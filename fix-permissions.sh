#!/bin/bash

echo "Fixing file permissions for nginx access..."

# Stop nginx temporarily
sudo systemctl stop nginx

# Create the directory structure with correct permissions
sudo mkdir -p /home/ubuntu/simple-course-shell-generator/public
sudo mkdir -p /home/ubuntu/simple-course-shell-generator/node_modules

# Set directory permissions - nginx needs execute permission on all parent directories
sudo chmod 755 /home
sudo chmod 755 /home/ubuntu
sudo chmod 755 /home/ubuntu/simple-course-shell-generator
sudo chmod 755 /home/ubuntu/simple-course-shell-generator/public

# Create index.html with proper content
cat > /home/ubuntu/simple-course-shell-generator/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #e74c3c;
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-align: center;
        }
        .status {
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .button {
            background: #e74c3c;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 10px 5px;
        }
        .button:hover {
            background: #c0392b;
        }
        .login-section {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 Canvas Course Shell Generator</h1>
        <div class="status">
            <strong>Status:</strong> Server is running successfully!
        </div>
        <p>The Canvas Course Shell Generator is now active and ready to use.</p>
        <p>This application allows educational administrators to create multiple Canvas course shells efficiently through an automated system.</p>
        
        <div class="login-section">
            <h2>Get Started</h2>
            <p>Please authenticate with your Digital Promise Okta account to access the course shell generator.</p>
            <div>
                <a href="/health" class="button">Check Health Status</a>
                <a href="/login" class="button">Login with Okta</a>
            </div>
        </div>
    </div>

    <script>
        // Check if user is authenticated
        fetch('/api/user')
            .then(response => {
                if (response.ok) {
                    return response.json();
                }
                throw new Error('Not authenticated');
            })
            .then(user => {
                // User is authenticated, show authenticated interface
                document.querySelector('.login-section').innerHTML = `
                    <h2>Welcome, ${user.firstName} ${user.lastName}!</h2>
                    <p>You are logged in as ${user.email}</p>
                    <div>
                        <a href="/logout" class="button">Logout</a>
                    </div>
                `;
            })
            .catch(error => {
                // User is not authenticated, show login section
                console.log('User not authenticated');
            });
    </script>
</body>
</html>
EOF

# Set file permissions (644 for files, 755 for directories)
sudo chmod 644 /home/ubuntu/simple-course-shell-generator/public/index.html

# Set ownership to ubuntu user but make readable by nginx
sudo chown -R ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator

# Make sure nginx can read the files by setting proper permissions
sudo chmod -R o+r /home/ubuntu/simple-course-shell-generator/public
sudo chmod o+x /home/ubuntu/simple-course-shell-generator/public

# Test that nginx can access the file
echo "Testing file access..."
sudo -u www-data test -r /home/ubuntu/simple-course-shell-generator/public/index.html
if [ $? -eq 0 ]; then
    echo "✓ nginx can read index.html"
else
    echo "✗ nginx cannot read index.html"
    echo "Setting additional permissions..."
    sudo chmod 755 /home/ubuntu/simple-course-shell-generator/public
    sudo chmod 644 /home/ubuntu/simple-course-shell-generator/public/index.html
    # Add other users read permission
    sudo chmod o+r /home/ubuntu/simple-course-shell-generator/public/index.html
fi

# Verify directory structure and permissions
echo "Directory structure and permissions:"
ls -la /home/ubuntu/simple-course-shell-generator/
ls -la /home/ubuntu/simple-course-shell-generator/public/

echo "Parent directory permissions:"
ls -ld /home/ubuntu/simple-course-shell-generator/
ls -ld /home/ubuntu/
ls -ld /home/

# Start nginx
sudo systemctl start nginx

echo ""
echo "Permission fix complete!"
echo "Test the application at: https://shell.dpvils.org"