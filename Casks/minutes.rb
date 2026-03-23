cask "minutes" do
  version "0.5.0"
  sha256 "ac7909e0a7d0a0c123716680baccc3c827fbcb8b9106d1e51fc1d2e7a4906635"

  url "https://github.com/silverstein/minutes/releases/download/v#{version}/Minutes-v#{version}-macos-arm64.zip"
  name "Minutes"
  desc "Privacy-first conversation memory — record, transcribe, search meetings locally"
  homepage "https://useminutes.app"

  depends_on macos: ">= :big_sur"
  depends_on arch: :arm64

  app "Minutes.app"

  postflight do
    system "xattr", "-cr", "#{appdir}/Minutes.app"
  end

  zap trash: [
    "~/.config/minutes",
    "~/.minutes",
  ]

  caveats <<~EOS
    Minutes.app is not signed with an Apple Developer certificate.
    On first launch, right-click the app and select "Open", then click
    "Open" again in the dialog to bypass Gatekeeper.

    Or remove the quarantine flag (the postflight script does this automatically):
      xattr -cr /Applications/Minutes.app

    To download a whisper model for transcription:
      minutes setup --model small

    For the CLI (record, stop, search from terminal):
      brew install silverstein/tap/minutes
  EOS
end
