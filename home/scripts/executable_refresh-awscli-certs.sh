#!/bin/sh
set -x

brew upgrade awscli
AWS_BIN="$(brew --prefix awscli)/libexec/bin"
"$AWS_BIN/pip" install --upgrade git+ssh://git.amazon.com/pkg/BenderLibIsengard

CERT_FILE="$("$AWS_BIN/python" -c 'import botocore; print(botocore.__path__[0])')/cacert.pem"
cp -v "$CERT_FILE" "$CERT_FILE.bak"
(
   security find-certificate -a -p ls "/System/Library/Keychains/SystemRootCertificates.keychain"
   security find-certificate -a -p ls "/Library/Keychains/System.keychain"
) > "$CERT_FILE"

