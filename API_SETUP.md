# API Configuration Setup

## For Development

1. Copy the example config file:
   ```bash
   cp Muorz/Config.plist.example Muorz/Config.plist
   ```

2. Edit `Muorz/Config.plist` and replace the placeholder values with your actual API keys:
   - Get your Gemini API key from: https://makersuite.google.com/app/apikey
   - Get your ChatGPT API key from: https://platform.openai.com/api-keys

3. The `Config.plist` file is automatically ignored by git to keep your API keys secure.

## For Production/TestFlight

For production builds, make sure to:
1. Create a `Config.plist` file with production API keys
2. Add the file to your Xcode project 
3. Verify the keys are properly loaded (check console logs)

## Security Notes

- ✅ `Config.plist` is in `.gitignore` - your API keys won't be committed
- ✅ Fallback keys are used for development if config file is missing
- ⚠️ Remove fallback keys before final production release
- ✅ The main `Info.plist` stays in version control with app metadata

## Troubleshooting

If you see "Using fallback API key for development" in the console:
1. Check that `Config.plist` exists in the `Muorz/` folder
2. Verify the key names match exactly: `GEMINI_API_KEY` and `CHATGPT_API_KEY`
3. Make sure the values don't contain "YOUR_ACTUAL" (placeholder text) 