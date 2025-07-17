# Create New Canvas API Token

## Method 1: Personal Access Token (Recommended)
1. Go to: https://dppowerfullearning.instructure.com/profile/settings
2. Scroll down to "Approved Integrations" section
3. Click "+ New Access Token"
4. Purpose: "Canvas Course Shell Generator"
5. Expiry: Set to 1 year from now
6. Copy the generated token

## Method 2: Developer Key Token
If Personal Access Token section is not available:
1. Go to: https://dppowerfullearning.instructure.com/accounts/1/developer_keys
2. Find the existing "Course Shell Generator" key (ID: 280980000000000004)
3. Click "Show Key" or "Regenerate"
4. Copy the API token

## Method 3: Generate from Existing Key
The existing Canvas Developer Key should have an associated API token:
- Client ID: 280980000000000004
- Client Secret: Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa

## Current Status
- Canvas OAuth infrastructure: Complete
- Canvas Developer Key: Configured and active
- Missing: Valid Canvas API token for fallback authentication

Please provide the new Canvas API token so I can update both production and development environments.