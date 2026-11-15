#!/usr/bin/env python3
"""Isolated deployment tests; never install packages or decrypt real secrets."""
import json
import os
from pathlib import Path
import pty
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = os.environ.get("CHEZMOI", "chezmoi")


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base / "home"
        self.home.mkdir()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_CACHE_HOME": str(self.base / "cache"),
            "XDG_STATE_HOME": str(self.base / "state"),
            "XDG_DATA_HOME": str(self.base / "data"),
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "TERM": "xterm",
            "USER": "dotfiles-test",
            "TMPDIR": str(self.base),
        }
        for key in ("ASK", "DOTFILES_SHELL", "DOTFILES_MINIMAL", "GITHUB_USER",
                    "FORGIT_NO_ALIASES", "PYENV_ROOT", "CONDA_PREFIX",
                    "NONINTERACTIVE", "CI", "BASH_ENV", "MAKEFLAGS", "MFLAGS"):
            self.env.pop(key, None)
        self.cfg = self.base / "config.json"
        self.data = {}
        self.configure()
        self.stub("brew")

    def run_command(self, args, *, check=True, **kwargs):
        result = subprocess.run(
            [str(arg) for arg in args], env=self.env, cwd=self.home,
            text=True, capture_output=True, **kwargs,
        )
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def configure(self, shell="fish", platform="linux-ubuntu",
                  email="test@example.org", minimal=True):
        self.data = {
            "name": "Test User", "email": email, "osid": platform,
            "osversion": "test", "config_state": {"minimal": minimal},
        }
        if shell is not None:
            self.data["config_state"]["shell"] = shell
        self.cfg.write_text(json.dumps({"sourceDir": str(ROOT), "data": self.data}))
        self.platform = platform

    def chez(self, *args, **kwargs):
        override = {"chezmoi": {
            "os": "darwin" if self.platform == "darwin" else "linux",
            "arch": "arm64", "homeDir": str(self.home),
        }}
        return self.run_command([
            CHEZMOI, "--config", self.cfg, "--source", ROOT,
            "--destination", self.home, "--cache", self.base / "cache",
            "--persistent-state", self.base / "chezmoi.boltdb",
            "--override-data", json.dumps(override), *args,
        ], **kwargs)

    def render(self, path):
        return self.chez("execute-template", "--file", ROOT / "home" / path).stdout

    def deploy(self):
        self.chez("apply", "--force", "--exclude", "encrypted,externals,scripts")

    def stub(self, name, body="exit 0"):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)
        return path

    def utility(self, code, *, terminal=False, check=True):
        script = f'''
source "{ROOT}/scripts/lib/utils.sh"
log::error() {{ printf '%s\\n' "$*" >&2; }}
log::always() {{ printf '%s\\n' "$*"; }}
{code}
'''
        if not terminal:
            return self.run_command(["bash", "-c", script], check=check)
        master, slave = pty.openpty()
        try:
            return self.run_command(["bash", "-c", script], stdin=slave, check=check,
                                    timeout=10)
        finally:
            os.close(slave)
            os.close(master)

    def fake_sudo(self):
        self.env["SUDO_LOG"] = str(self.base / "sudo.log")
        self.stub("id", 'if [ "$1" = -u ]; then echo 1000; else /usr/bin/id "$@"; fi')
        self.stub("sudo", '''
printf '%s\\n' "$*" >> "$SUDO_LOG"
case "$*" in
  "-n -v") [ "${SUDO_CACHED:-0}" = 1 ] ;;
  "-v") [ "${SUDO_DENIED:-0}" != 1 ] ;;
  *) exit 0 ;;
esac''')

    def hook(self, name, family="arch"):
        root = self.base / "source"
        (root / "home").mkdir(parents=True, exist_ok=True)
        common = root / "scripts/common.sh"
        common.parent.mkdir(parents=True, exist_ok=True)
        common.write_text(f'''
source "{ROOT}/scripts/common.sh"
util::linux_distro() {{ printf '%s\\n' "{family}"; }}
''')
        script = self.base / "hook.sh"
        script.write_text(self.render(name).replace(str(ROOT / "home"), str(root / "home")))
        return script

    def fish(self, code, interactive=False, check=True):
        return self.run_command(
            ["fish", "-i" if interactive else "-c", "-c", code]
            if interactive else ["fish", "-c", code],
            check=check,
        )

    def test_target_matrix(self):
        for shell in ("fish", "zsh"):
            for platform in ("darwin", "linux-ubuntu", "linux-arch", "linux-cachyos"):
                for email in ("test@example.org", "test@amazon.com", "test@microsoft.com"):
                    with self.subTest(shell=shell, platform=platform, email=email):
                        self.configure(shell, platform, email)
                        targets = self.chez("managed", "--exclude", "encrypted,externals,scripts").stdout
                        self.assertEqual(".zshrc" in targets, shell == "zsh")
                        self.assertEqual(".config/fish/config.fish" in targets, shell == "fish")
                        if shell == "fish":
                            self.assertNotIn(".config/zsh", targets)
                            self.assertEqual("40-amazon.fish" in targets, email.endswith("@amazon.com"))
                            self.assertEqual("40-microsoft.fish" in targets, email.endswith("@microsoft.com"))
                            self.assertEqual("30-macos.fish" in targets, platform == "darwin")
                            self.assertEqual("41-midway.fish" in targets,
                                             platform == "darwin" and email.endswith("@amazon.com"))
                        self.assertIn(".config/starship.toml", targets)

    def test_external_and_package_selection(self):
        for shell in ("fish", "zsh"):
            self.configure(shell)
            externals = self.render(".chezmoiexternal.toml")
            self.assertEqual('[".oh-my-zsh"]' in externals, shell == "zsh")
            self.assertEqual("zsh-autosuggestions" in externals, shell == "zsh")
            self.assertIn('[".config/depot_tools"]', externals)
            self.assertIn(f'shell_name="{shell}"',
                          self.render("run_onchange_before_00_shell-packages.sh.tmpl"))
            fzf = self.render("run_once_02_fzf-installer.sh.tmpl")
            self.assertEqual("--bin" in fzf, shell == "fish")
        self.assertNotIn("install -y zsh", self.render("run_once_01_ubuntu-packages.sh.tmpl"))

    def test_old_configuration_defaults_to_zsh(self):
        self.configure(None)
        self.assertIn('[".oh-my-zsh"]', self.render(".chezmoiexternal.toml"))
        self.assertIn('shell_name="zsh"',
                      self.render("run_onchange_before_00_shell-packages.sh.tmpl"))

    def test_invalid_shell_is_rejected(self):
        self.configure("invalid")
        result = self.chez("execute-template", '{{ includeTemplate "shell" . }}', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be zsh or fish", result.stderr)
        result = self.run_command(
            ["make", "-C", ROOT, "DOTFILES_SHELL=invalid", "apply"], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be zsh or fish", result.stderr)

    def test_switch_keeps_inactive_files_unchanged(self):
        self.configure("zsh")
        self.deploy()
        zshrc = self.home / ".zshrc"
        original = zshrc.read_bytes()
        self.configure("fish")
        self.deploy()
        self.assertEqual(zshrc.read_bytes(), original)
        fishrc = self.home / ".config/fish/config.fish"
        fish_original = fishrc.read_bytes()
        fish_hook = self.render("run_onchange_before_00_shell-packages.sh.tmpl")
        self.configure("zsh")
        self.deploy()
        self.assertEqual(fishrc.read_bytes(), fish_original)
        self.assertNotEqual(fish_hook, self.render("run_onchange_before_00_shell-packages.sh.tmpl"))

    def test_initialization_and_persisted_selection(self):
        cfg = self.base / "init.yaml"
        self.env["DOTFILES_SHELL"] = "fish"
        args = [CHEZMOI, "--source", ROOT, "--destination", self.home,
                "--config", cfg, "--persistent-state", self.base / "init.boltdb",
                "init", "--no-tty"]
        self.run_command(args)
        self.assertIn('shell: "fish"', cfg.read_text())
        self.env.pop("DOTFILES_SHELL")
        self.run_command(args)
        self.assertIn('shell: "fish"', cfg.read_text())

    def test_explicit_selection_can_repair_invalid_saved_data(self):
        self.configure("invalid")
        self.env["DOTFILES_SHELL"] = "fish"
        result = self.chez("execute-template", "--init", "--file", ROOT / "home/.chezmoi.yaml.tmpl")
        self.assertIn('shell: "fish"', result.stdout)

    def test_ask_prompts_for_shell(self):
        self.env["ASK"] = "1"
        result = self.chez(
            "execute-template", "--init",
            "--promptChoice", "interactive shell=fish",
            "--promptBool", "minimal (skip Brew bundle)=true",
            "--promptString", "full name=Test User,email=test@example.org",
            "--file", ROOT / "home/.chezmoi.yaml.tmpl",
        )
        self.assertIn('shell: "fish"', result.stdout)

    def test_reinit_wrapper_retains_saved_shell(self):
        cfg = self.base / "init.yaml"
        self.env.update(DOTFILES_SHELL="fish", CFG_FILE=str(cfg), VERBOSE="0")
        self.env["PATH"] = str(Path(CHEZMOI).resolve().parent) + ":" + self.env["PATH"]
        self.run_command(["bash", ROOT / "scripts/chez.sh", "init"])
        self.env.pop("DOTFILES_SHELL")
        self.env["REINIT"] = "true"
        self.run_command(["bash", ROOT / "scripts/chez.sh", "init"])
        self.assertIn('shell: "fish"', cfg.read_text())

    def test_minimal_shell_dependency_hook_with_fake_package_managers(self):
        log = self.base / "packages"
        self.stub("brew", f'printf "%s\\n" "$*" >> "{log}"')
        self.stub("sudo", f'printf "%s\\n" "$*" >> "{log}"')
        bash_env = self.base / "bash-env"
        bash_env.write_text("""
command() {
  if [[ "$1" == -v && ( "$2" == fish || "$2" == starship ) ]]; then
    return 1
  fi
  builtin command "$@"
}
""")
        self.env["BASH_ENV"] = str(bash_env)
        for platform in ("darwin", "linux-ubuntu", "linux-arch", "linux-cachyos"):
            self.configure(platform=platform, minimal=True)
            script = self.hook("run_onchange_before_00_shell-packages.sh.tmpl",
                               "ubuntu" if platform == "linux-ubuntu" else "arch")
            log.write_text("")
            self.run_command(["bash", script])
            packages = log.read_text()
            self.assertIn("fish", packages)
            self.assertIn("starship", packages)
            self.assertNotIn("zsh", packages)

    def test_sudo_cached_and_terminal_authentication(self):
        self.fake_sudo()
        self.env["SUDO_CACHED"] = "1"
        self.utility("util::ensure_sudo")
        log = Path(self.env["SUDO_LOG"])
        self.assertEqual(log.read_text().splitlines(), ["-n -v"])
        log.write_text("")
        self.env["SUDO_CACHED"] = "0"
        self.utility("util::ensure_sudo", terminal=True)
        self.assertEqual(log.read_text().splitlines(), ["-n -v", "-v"])

    def test_sudo_unattended_and_denied_authentication(self):
        self.fake_sudo()
        result = self.utility("util::ensure_sudo", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sudo -v", result.stderr)
        for flag in ("CI", "NONINTERACTIVE"):
            with self.subTest(flag=flag):
                self.env[flag] = "1"
                result = self.utility("util::ensure_sudo", terminal=True, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("sudo -v", result.stderr)
                self.env.pop(flag)
        self.assertNotIn("-v\n-v", Path(self.env["SUDO_LOG"]).read_text())
        self.env["SUDO_DENIED"] = "1"
        result = self.utility("util::ensure_sudo", terminal=True, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("authentication failed", result.stderr)

    def test_sudo_missing_and_root_native_execution(self):
        self.stub("id", "echo 1000")
        result = self.utility('''
util::is_available() { return 1; }
util::ensure_sudo
''', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sudo is not installed", result.stderr)
        self.stub("id", "echo 0")
        result = self.utility("util::run_privileged printf '%s' root-command")
        self.assertEqual(result.stdout, "root-command")

    def test_distro_family_uses_exact_tokens_and_derivatives(self):
        for distro, likes, expected in (
            ("arch", "", "arch"), ("cachyos", "arch", "arch"),
            ("manjaro", "arch", "arch"), ("ubuntu", "debian", "ubuntu"),
            ("linuxmint", "ubuntu debian", "ubuntu"), ("debian", "", "ubuntu"),
            ("notarch", "notdebian", "unknown"), ("ubuntu", "arch", "ubuntu"),
        ):
            release = self.base / "os-release"
            release.write_text(f'ID={distro}\nID_LIKE="{likes}"\n')
            result = self.utility(f'util::linux_distro "{release}"')
            self.assertEqual(result.stdout.strip(), expected)

    def test_homebrew_discovery_and_shellenv_failures(self):
        self.stub("brew", '''
if [ "$1" = shellenv ]; then
  [ "${FAIL_SHELLENV:-0}" != 1 ] || exit 8
  printf 'export HOMEBREW_PREFIX="%s"\\n' "$HOME/custom-brew"
fi''')
        result = self.utility('util::setup_brew && printf "%s" "$HOMEBREW_PREFIX"')
        self.assertEqual(result.stdout, str(self.home / "custom-brew"))
        self.env["FAIL_SHELLENV"] = "1"
        result = self.utility("util::setup_brew", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Could not load the Homebrew environment", result.stderr)

    def test_homebrew_install_failures_and_fresh_environment(self):
        prefix = self.home / "brew"
        self.env["TEST_BREW_PREFIX"] = str(prefix)
        self.env["PATH"] = str(prefix / "bin") + ":" + self.env["PATH"]
        installer = self.base / "installer"
        self.env["TEST_INSTALLER"] = str(installer)
        installer.write_text('''
mkdir -p "$TEST_BREW_PREFIX/bin"
cp "$TEST_BREW_TEMPLATE" "$TEST_BREW_PREFIX/bin/brew"
chmod +x "$TEST_BREW_PREFIX/bin/brew"
''')
        brew = self.base / "brew-template"
        brew.write_text('''#!/bin/sh
case "$1" in
  shellenv) printf 'export HOMEBREW_PREFIX="%s"\\n' "$TEST_BREW_PREFIX" ;;
  analytics) echo "analytics configured" ;;
esac
''')
        self.env["TEST_BREW_TEMPLATE"] = str(brew)
        self.stub("curl", '''
case "${DOWNLOAD_MODE:-success}" in
  fail) exit 6 ;;
  empty) exit 0 ;;
  installer-fail) echo "exit 9" ;;
  *) cat "$TEST_INSTALLER" ;;
esac''')
        for mode, message in (("fail", "Could not download"), ("empty", "is empty")):
            self.env["DOWNLOAD_MODE"] = mode
            result = self.utility(f'util::install_homebrew "{prefix}"', check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(message, result.stderr)
        self.env["DOWNLOAD_MODE"] = "installer-fail"
        result = self.utility(f'util::install_homebrew "{prefix}"', check=False)
        self.assertEqual(result.returncode, 9)
        self.env["DOWNLOAD_MODE"] = "success"
        result = self.utility(f'util::install_homebrew "{prefix}"; printf "%s" "$HOMEBREW_PREFIX"')
        self.assertIn(str(prefix), result.stdout)
        self.assertIn("analytics configured", result.stdout)

    def test_homebrew_missing_privilege_stops_before_download(self):
        if os.geteuid() == 0:
            self.skipTest("directory permission preflight needs an unprivileged user")
        self.fake_sudo()
        protected = self.base / "protected"
        protected.mkdir(mode=0o500)
        self.stub("curl", 'echo "UNEXPECTED DOWNLOAD" >&2; exit 99')
        try:
            result = self.utility(f'util::install_homebrew "{protected}/brew"', check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("sudo -v", result.stderr)
            self.assertNotIn("UNEXPECTED DOWNLOAD", result.stderr)
        finally:
            protected.chmod(0o700)

    def test_preinstalled_tools_do_not_download_or_authenticate(self):
        self.fake_sudo()
        self.stub("brew", '''
[ "$1" != shellenv ] || printf 'export HOMEBREW_PREFIX="%s"\\n' "$HOME/brew"
''')
        for name in ("chezmoi", "age", "cc"):
            self.stub(name)
        self.stub("curl", "exit 99")
        for _ in range(2):
            self.run_command(["bash", ROOT / "scripts/install_tools.sh"])
        self.assertFalse(Path(self.env["SUDO_LOG"]).exists())

    def test_make_stops_on_installer_or_logger_failure(self):
        root = self.base / "make-fixture"
        scripts = root / "scripts"
        (scripts / "make_rules").mkdir(parents=True)
        shutil.copyfile(ROOT / "Makefile", root / "Makefile")
        logger = scripts / "make_rules/log_status.sh"
        logger.write_text("#!/bin/sh\nexit 0\n")
        logger.chmod(0o755)
        marker = self.base / "applied"
        chez = scripts / "chez.sh"
        chez.write_text(f'#!/bin/sh\ntouch "{marker}"\n')
        chez.chmod(0o755)
        tools = scripts / "install_tools.sh"
        log = self.base / "installation log"
        tools.write_text('echo "installer stdout"; echo "installer stderr" >&2; exit 7\n')
        command = ["make", "-C", root, f"LOGFILE={log}", f"CFG_FILE={self.base}/chezmoi.yaml", "apply"]
        result = self.run_command(command, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())
        self.assertIn("installer stdout", log.read_text())
        self.assertIn("installer stderr", log.read_text())
        tools.write_text('echo "installer success"\n')
        self.stub("tee", "cat >/dev/null; exit 4")
        result = self.run_command(command, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())

    def test_homebrew_bundle_matrix_and_minimal_mode(self):
        log = self.base / "bundles"
        self.env["BUNDLE_LOG"] = str(log)
        self.stub("brew", '''
if [ "$1" = bundle ]; then printf '%s\\n' "$*" >> "$BUNDLE_LOG"; fi
''')
        for platform in ("darwin", "linux-ubuntu", "linux-arch", "linux-cachyos"):
            for email in ("test@example.org", "test@microsoft.com", "test@amazon.com"):
                for minimal in (False, True):
                    with self.subTest(platform=platform, email=email, minimal=minimal):
                        self.configure(platform=platform, email=email, minimal=minimal)
                        script = self.hook("run_onchange_01_install-packages.sh.tmpl")
                        log.write_text("")
                        result = self.run_command(["bash", script])
                        bundles = [Path(line.split(" --file ", 1)[1]).name
                                   for line in log.read_text().splitlines()]
                        if minimal:
                            self.assertEqual(bundles, [])
                            self.assertIn("Skipping optional Homebrew bundles", result.stdout)
                            continue
                        expected = []
                        if platform == "darwin":
                            expected += ["Brewfile", "Brewfile-common", "Brewfile-Darwin-arm64"]
                            if email.endswith("@amazon.com"):
                                expected.append("Brewfile-Amzn")
                        else:
                            if platform == "linux-ubuntu":
                                expected.append("Brewfile-Ubuntu")
                            expected.append("Brewfile-common")
                        if email.endswith("@microsoft.com"):
                            expected.append("Brewfile-Msft")
                        self.assertEqual(bundles, expected)

    def test_bundle_failure_stops_subsequent_bundles(self):
        self.configure(platform="linux-cachyos", email="test@microsoft.com", minimal=False)
        log = self.base / "failed-bundles"
        self.stub("brew", f'''
if [ "$1" = bundle ]; then
  printf '%s\\n' "$*" >> "{log}"
  exit 7
fi''')
        script = self.hook("run_onchange_01_install-packages.sh.tmpl")
        result = self.run_command(["bash", script], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Brewfile-common", log.read_text())
        self.assertNotIn("Brewfile-Msft", log.read_text())

    def test_missing_shell_on_cachyos_uses_pacman(self):
        self.fake_sudo()
        self.env["SUDO_CACHED"] = "1"
        self.stub("brew")
        bash_env = self.base / "missing-shells"
        bash_env.write_text('''
command() {
  if [[ "$1" == -v && ( "$2" == fish || "$2" == zsh ) ]]; then return 1; fi
  builtin command "$@"
}
''')
        self.env["BASH_ENV"] = str(bash_env)
        for shell in ("fish", "zsh"):
            self.configure(shell, "linux-cachyos")
            script = self.hook("run_onchange_before_00_shell-packages.sh.tmpl")
            Path(self.env["SUDO_LOG"]).write_text("")
            self.run_command(["bash", script])
            log = Path(self.env["SUDO_LOG"]).read_text()
            self.assertIn(f"-n pacman -S --needed --noconfirm {shell}", log)
            self.assertNotIn("apt-get", log)

    def test_bundle_selection_changes_rendered_onchange_script(self):
        name = "run_onchange_01_install-packages.sh.tmpl"
        self.configure(platform="linux-cachyos", minimal=False)
        full = self.render(name)
        self.assertEqual(full, self.render(name))
        self.configure(platform="linux-cachyos", minimal=True)
        self.assertNotEqual(full, self.render(name))
        self.configure(platform="linux-cachyos", minimal=False, email="test@microsoft.com")
        self.assertNotEqual(full, self.render(name))

    def test_bundle_manifest_changes_trigger_onchange_without_repeating(self):
        self.configure(platform="linux-cachyos", minimal=False)
        source = self.base / "onchange-source"
        home = source / "home"
        home.mkdir(parents=True)
        (source / ".chezmoiroot").write_text("home\n")
        for manifest in (ROOT / "home").glob("Brewfile*"):
            shutil.copyfile(manifest, home / manifest.name)
        hook = "run_onchange_01_install-packages.sh.tmpl"
        shutil.copyfile(ROOT / "home" / hook, home / hook)
        (source / "scripts").mkdir()
        (source / "scripts/common.sh").write_text(f'source "{ROOT}/scripts/common.sh"\n')
        log = self.base / "onchange.log"
        self.stub("brew", f'''
if [ "$1" = bundle ]; then printf '%s\\n' "$*" >> "{log}"; fi
''')
        self.chez("--source", source, "apply", "--include", "scripts", "--force")
        first = log.read_text()
        self.chez("--source", source, "apply", "--include", "scripts", "--force")
        self.assertEqual(log.read_text(), first)
        with (home / "Brewfile-Ubuntu").open("a") as manifest:
            manifest.write("\n# Unselected profile changed\n")
        self.chez("--source", source, "apply", "--include", "scripts", "--force")
        self.assertEqual(log.read_text(), first)
        with (home / "Brewfile-common").open("a") as manifest:
            manifest.write("\n# Selected manifest changed\n")
        self.chez("--source", source, "apply", "--include", "scripts", "--force")
        self.assertEqual(log.read_text(), first + first)

    def test_bootstrap_privileges_and_derivative_detection(self):
        self.fake_sudo()
        functions = self.base / "bootstrap-functions.sh"
        functions.write_text((ROOT / "bootstrap.sh").read_text().replace('\nmain "$@"\n', "\n"))
        for distro, likes, expected in (
            ("cachyos", "arch", "arch"), ("linuxmint", "ubuntu debian", "ubuntu"),
            ("notarch", "notdebian", "linux-unknown"),
        ):
            release = self.base / "bootstrap-release"
            release.write_text(f'ID={distro}\nID_LIKE="{likes}"\n')
            result = self.run_command([
                "sh", "-c", f'. "{functions}"; detect_os "{release}"',
            ])
            self.assertEqual(result.stdout.strip(), expected)
        code = f'. "{functions}"; ensure_sudo'
        result = self.run_command(["sh", "-c", code], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sudo -v", result.stderr)
        master, slave = pty.openpty()
        try:
            self.run_command(["sh", "-c", code], stdin=slave, timeout=10)
        finally:
            os.close(slave)
            os.close(master)
        self.assertEqual(Path(self.env["SUDO_LOG"]).read_text().splitlines(),
                         ["-n -v", "-n -v", "-v"])
        self.stub("brew", "exit 8")
        result = self.run_command(["sh", "-c", f'. "{functions}"; setup_brew'], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Could not load the Homebrew environment", result.stderr)

    def test_microsoft_cask_is_macos_only(self):
        ruby = os.environ.get("RUBY") or shutil.which("ruby")
        if not ruby:
            self.skipTest("Ruby is not installed")
        program = '''
module OS
  def self.mac?; ENV["TEST_MACOS"] == "1"; end
end
def brew(name); puts "brew:#{name}"; end
def cask(name); puts "cask:#{name}"; end
load ARGV[0]
'''
        for macos in ("0", "1"):
            self.env["TEST_MACOS"] = macos
            result = self.run_command([
                ruby, "-e", program, ROOT / "home/Brewfile-Msft",
            ])
            self.assertIn("brew:azure-cli", result.stdout)
            self.assertEqual("cask:microsoft-edge" in result.stdout, macos == "1")

    def test_homebrew_environment_path_order_stays_stable(self):
        for directory in ("bin", "sbin"):
            (self.home / "brew" / directory).mkdir(parents=True)
        self.stub("brew", '''
if [ "$1" = shellenv ]; then
  printf 'fish_add_path --path --move "%s/bin" "%s/sbin"\\n' "$HOME/brew" "$HOME/brew"
fi''')
        self.deploy()
        result = self.fish(
            'printf "%s\\n" $PATH; source ~/.config/fish/conf.d/00-environment.fish; printf "SPLIT\\n"; printf "%s\\n" $PATH'
        )
        before, after = result.stdout.split("SPLIT\n")
        self.assertEqual(before, after)
        self.assertEqual(before.splitlines()[0], str(self.home / "scripts"))

    def test_post_apply_only_prints_login_shell_instructions(self):
        self.stub("fish")
        self.stub("brew")
        self.stub("getent", 'echo "test:x:1:1:Test:/tmp:/bin/bash"')
        self.stub("dscl", 'echo "UserShell: /bin/zsh"')
        self.stub("chsh", "exit 99")
        for platform in ("darwin", "linux-ubuntu"):
            self.configure(platform=platform)
            script = self.base / "instructions.sh"
            script.write_text(self.render("run_90_shell-instructions.sh.tmpl"))
            result = self.run_command(["bash", script])
            self.assertIn(f"chsh -s {self.bin}/fish", result.stdout)
            self.assertIn("login shell has not been changed", result.stdout)

    def test_wrapper_rejects_apply_override(self):
        self.env.update(CFG_FILE=str(self.cfg), DOTFILES_SHELL="zsh", VERBOSE="0")
        self.env["PATH"] = str(Path(CHEZMOI).resolve().parent) + ":" + self.env["PATH"]
        result = self.run_command(["bash", ROOT / "scripts/chez.sh", "apply"], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("make reinit", result.stdout + result.stderr)

    def test_rendered_shell_syntax(self):
        for shell in ("fish", "zsh"):
            for platform in ("darwin", "linux-ubuntu", "linux-arch"):
                self.configure(shell, platform, "test@amazon.com")
                self.deploy()
                for file in (self.home / ".config/fish").rglob("*.fish"):
                    self.run_command(["fish", "--no-execute", file])
                    self.run_command(["fish_indent", "--check", file])
                if shell == "zsh":
                    self.run_command(["zsh", "-n", self.home / ".zshrc"])
                for file in (ROOT / "home").glob("*sh.tmpl"):
                    rendered = self.base / "rendered.sh"
                    rendered.write_text(self.render(file.name))
                    self.run_command(["bash", "-n", rendered])

    def test_shellcheck(self):
        shellcheck = os.environ.get("SHELLCHECK") or shutil.which("shellcheck")
        if not shellcheck:
            self.skipTest("ShellCheck is not installed")
        self.run_command([
            shellcheck, "-s", "bash", "--severity=error",
            *sorted((ROOT / "home/dot_config/shell").glob("*.bash")),
            ROOT / "scripts/lib/run_chezmoi.sh", ROOT / "bootstrap.sh",
        ])
        self.run_command([
            shellcheck, ROOT / "scripts/install_tools.sh",
            ROOT / "scripts/lib/utils.sh", ROOT / "bootstrap.sh",
        ])
        self.run_command([shellcheck, ROOT / "home/scripts/executable_dotfiles-helper"])
        self.run_command([
            shellcheck, "-s", "sh",
            ROOT / "home/scripts/executable_get-persistent-configs",
            ROOT / "home/scripts/executable_list-persistent-configs",
        ])
        for name in ("run_onchange_before_00_shell-packages.sh.tmpl",
                     "run_onchange_01_install-packages.sh.tmpl",
                     "run_90_shell-instructions.sh.tmpl",
                     "run_once_02_fzf-installer.sh.tmpl"):
            script = self.base / "lint.sh"
            script.write_text(self.render(name))
            self.run_command([shellcheck, script])

    def test_noninteractive_startup_is_quiet_and_idempotent(self):
        self.deploy()
        result = self.fish('printf "%s\\n" $PATH; source ~/.config/fish/conf.d/00-environment.fish; printf "SPLIT\\n"; printf "%s\\n" $PATH')
        before, after = result.stdout.split("SPLIT\n")
        self.assertEqual(before, after)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.fish("true").stdout, "")

    def test_interactive_integrations_and_forgit_precedence(self):
        self.stub("starship", 'printf \'set -g __starship_started 1\\n\'')
        self.deploy()
        result = self.fish(
            'test "$__starship_started" = 1; or exit 3; functions ga; functions gd',
            interactive=True)
        self.assertIn('dotfiles-helper forgit', result.stdout)
        self.assertEqual(result.stderr, "")

    def test_zsh_startup_uses_shared_prompt_and_helpers(self):
        self.configure("zsh", email="test@microsoft.com")
        self.stub("starship", "printf 'typeset -g __starship_started=1\\n'")
        self.stub("fnm")
        self.stub("pyenv")
        self.deploy()
        for file in (".oh-my-zsh/oh-my-zsh.sh",
                     ".config/zsh/plugins/zsh-autoenv/autoenv.zsh"):
            path = self.home / file
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("")
        result = self.run_command([
            "zsh", "-i", "-c",
            '[[ "$__starship_started" == 1 ]] || exit 3; ip2dec 172.17.0.1',
        ])
        self.assertEqual(result.stdout.strip(), str(172 * 256**3 + 17 * 256**2 + 1))
        self.assertEqual(result.stderr, "")

    def test_forgit_preserves_arguments_and_uses_bash_previews(self):
        self.stub("starship")
        self.stub("git", '''
case "$1" in
  rev-parse|config) exit 0 ;;
  log) echo "fake log" ;;
  *) printf "<%s>\\n" "$@" ;;
esac''')
        self.stub("fzf", 'case "$1" in --version) echo 0.48.0 ;; --fish) exit 0 ;; *) printf "%s\\n" "$SHELL"; exit 4 ;; esac')
        self.deploy()
        result = self.fish('ga "file with spaces"', interactive=True)
        self.assertIn("<file with spaces>", result.stdout)
        self.env["SHELL"] = "/usr/bin/fish"
        result = self.fish("glo", interactive=True, check=False)
        self.assertEqual(result.returncode, 4)
        self.assertTrue(result.stdout.strip().endswith("/bash"))

    def test_forgit_alias_override(self):
        self.stub("starship")
        self.deploy()
        self.env["forgit_add"] = "custom_add"
        result = self.fish("functions custom_add", interactive=True)
        self.assertIn("forgit::add", result.stdout)

    def test_bitbake_preserves_arguments_and_failure(self):
        self.configure(email="test@microsoft.com")
        self.stub("starship")
        self.stub("bitbake", 'printf "<%s>\\n" "$@"; exit 7')
        self.deploy()
        result = self.fish('bbclean "recipe with spaces"', interactive=True, check=False)
        self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual(result.stdout, "<recipe with spaces:do_clean>\n<recipe with spaces:do_cleansstate>\n")

    def test_rm_arguments_environment_and_arithmetic(self):
        self.configure(email="test@microsoft.com")
        self.stub("starship")
        self.stub("gum")
        self.stub("ssh", 'printf "ASKPASS=%s\\n" "$SSH_ASKPASS"; printf "<%s>\\n" "$@"')
        self.deploy()
        result = self.fish('ssh-bmc "test host" 2222 "echo spaced"', interactive=True)
        self.assertIn("ASKPASS=" + str(self.home / ".bmc-pass"), result.stdout)
        self.assertIn("<admin@test host>", result.stdout)
        self.assertIn("<echo spaced>", result.stdout)
        result = self.fish("ip2dec 172.17.0.1", interactive=True)
        self.assertEqual(result.stdout.strip(), str(172 * 256**3 + 17 * 256**2 + 1))
        result = self.fish("rmPortForward 172.17.0.1 2", interactive=True)
        self.assertIn("<-L2122:172.17.0.5:22>", result.stdout)
        self.assertIn("<-L2543:172.17.0.5:443>", result.stdout)

    def test_logged_rm_preserves_ssh_failure(self):
        self.configure(email="test@microsoft.com")
        self.stub("starship")
        self.stub("gum")
        self.stub("ssh", 'echo "remote output"; exit 7')
        self.env["LOG_FILE"] = str(self.base / "ssh log")
        self.deploy()
        result = self.fish("ssh-bmc localhost 2222", interactive=True, check=False)
        self.assertEqual(result.returncode, 7)
        self.assertIn("remote output", result.stdout)

    def test_ado_has_no_pat_helpers_and_preserves_git_arguments(self):
        self.configure(email="test@microsoft.com")
        self.stub("starship")
        self.stub("git", '''
case "$1" in
  rev-parse) echo .git ;;
  symbolic-ref) echo feature/test ;;
  config) echo upstream ;;
  *) printf "<%s>\\n" "$@" ;;
esac''')
        self.deploy()
        result = self.fish("ado-push -f", interactive=True)
        self.assertEqual(result.stdout, "<push>\n<upstream>\n<--force>\n<feature/test:refs/heads/feature/test>\n")
        for path in (ROOT / "home/dot_config").rglob("*"):
            if path.is_file() and path.suffix in (".bash", ".zshrc", ".fish"):
                self.assertNotIn("ado-generate-pat", path.read_text())
                self.assertNotIn("ado-push-pat", path.read_text())

    def test_amazon_directory_changes_and_cdd_dependency(self):
        self.configure(email="test@amazon.com")
        self.stub("starship")
        code = self.home / "code"
        (code / "a-package").mkdir(parents=True)
        self.stub("git")
        self.deploy()
        result = self.fish('git-package a-package; pwd', interactive=True)
        self.assertEqual(result.stdout.strip(), str(code / "a-package"))
        result = self.fish('cdd_sync .', interactive=True, check=False)
        self.assertEqual(result.returncode, 127)
        self.assertIn("DEV_TOOL_BIN", result.stderr)
        result = self.fish(
            'set -l previous "$PERL5LIB"; source ~/.config/fish/conf.d/40-amazon.fish; test "$previous" = "$PERL5LIB"',
            interactive=True)
        self.assertEqual(result.stderr, "")

    def test_bookmark_directory_effect_and_extraction_failure(self):
        self.stub("starship")
        self.deploy()
        folder = self.home / "with spaces"
        folder.mkdir()
        result = self.fish('cd "with spaces"; wd add test; cd ..; wd test; pwd', interactive=True)
        self.assertEqual(result.stdout.strip(), str(folder))
        unknown = self.home / "archive.unknown"
        unknown.touch()
        result = self.fish(f'extract "{unknown}"', interactive=True, check=False)
        self.assertEqual(result.returncode, 2)
        self.assertIn("unsupported archive", result.stderr)


if __name__ == "__main__":
    for tool in (CHEZMOI, "fish", "zsh"):
        if not shutil.which(tool):
            raise SystemExit(f"Required validation tool not found: {tool}")
    unittest.main()
