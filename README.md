# swiftbar-buildkite-status
SwiftBar plugin to show recent BuildKite builds


## Steps to set up:
1. Go to [BuildKite Settings](https://buildkite.com/user/api-access-tokens) and create a new API token.
1. Download the `buildkite_status.30s.rb` file and save it to you SwiftBar plugins folder
2. Edit the downloaded file and fill in the environment variables at the top of the file
    * Org name can be found from a regular BuildKite URL
    * Branches should be a JSON object that maps pipeline names to a string of branch names separated by `;` (the SwiftBar metadata parser currently will split this up incorrectly if you use a comma or a JSON array)