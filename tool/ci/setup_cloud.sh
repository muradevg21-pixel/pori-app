#!/usr/bin/env bash
# Installs Flutter + Android SDK in a fresh Linux cloud container (idempotent).
FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.50.1-stable.tar.xz
CLT_URL=https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
export ANDROID_HOME=/opt/android-sdk
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ ! -x /opt/flutter/bin/flutter ]; then
  curl -sfL "$FLUTTER_URL" | tar xJ -C /opt
fi
git config --global --add safe.directory /opt/flutter
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools" /tmp/clt
  curl -sfLo /tmp/clt/clt.zip "$CLT_URL"
  unzip -q -o /tmp/clt/clt.zip -d /tmp/clt
  mv /tmp/clt/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf /tmp/clt
fi
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-36" "build-tools;36.0.0" >/dev/null
/opt/flutter/bin/flutter config --no-analytics --android-sdk "$ANDROID_HOME" >/dev/null 2>&1
mkdir -p ~/.gradle/init.d
cp "$HERE/maven-mirror.gradle" ~/.gradle/init.d/maven-mirror.gradle
grep -q "repository.max.retries" ~/.gradle/gradle.properties 2>/dev/null || cat >> ~/.gradle/gradle.properties <<'PROPS'
org.gradle.parallel=false
org.gradle.workers.max=2
systemProp.org.gradle.internal.repository.max.retries=12
systemProp.org.gradle.internal.repository.initial.backoff=2000
PROPS
(cd "$HERE/../.." && /opt/flutter/bin/flutter pub get >/dev/null 2>&1)
echo "PORI cloud setup done"
