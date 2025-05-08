# AdSedareMattermost

AdSedareMattermost is a two-factor authentication provider for Adsedare that uses Mattermost to receive the 2FA code. It expects a lambda function that will extract the 2FA code from the array fo latest messages. This way it can be used with any SMS relay bots. It will wait for the 2FA code for a specified amount of time and retry if lambda function does not return a value.

## Configuration

```bash
export ADSEDARE_MM_TOKEN="mrm_your_bot_token"
export ADSEDARE_MM_HOST="https://your_mattermost_instance.com"

export ADSEDARE_MM_TEAM_ID="your_team_id"
# or
export ADSEDARE_MM_TEAM_NAME="Your Team Name"

export ADSEDARE_MM_CHANNEL_ID="your_channel_id"
# or
export ADSEDARE_MM_CHANNEL_NAME="Your Channel Name"

export ADSEDARE_MM_TIMEOUT_SECONDS="5" # How many seconds to wait for the 2FA code
export ADSEDARE_MM_RETRY_LIMIT="5" # How many times to retry
```

## Usage

```ruby
# TODO: Update after Adsedare release
provider = AdsedareMattermost::Provider.new(
    lambda do |messages|
        messages.last.match(/\d{6}/).to_s
    end
)
Starship::set_provider(provider)
```
