#!/bin/bash

echo "Updating frontend with full Canvas Course Shell Generator interface..."

# Create the complete index.html with full functionality
cat > /home/ubuntu/simple-course-shell-generator/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        h1 {
            color: #e74c3c;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.1rem;
        }
        
        .card {
            background: #fff;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
            color: #555;
        }
        
        input, select, textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        
        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: #e74c3c;
        }
        
        .button {
            background: #e74c3c;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            transition: background-color 0.3s;
            text-decoration: none;
            display: inline-block;
        }
        
        .button:hover {
            background: #c0392b;
        }
        
        .button:disabled {
            background: #bdc3c7;
            cursor: not-allowed;
        }
        
        .shell-form {
            border: 2px solid #ecf0f1;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            background: #fafafa;
        }
        
        .shell-form h3 {
            color: #2c3e50;
            margin-bottom: 15px;
        }
        
        .form-row {
            display: flex;
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .form-row .form-group {
            flex: 1;
            margin-bottom: 0;
        }
        
        .status-message {
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
            color: #666;
        }
        
        .activity-item {
            padding: 15px;
            border-left: 4px solid #e74c3c;
            background: #fff;
            margin-bottom: 10px;
            border-radius: 0 4px 4px 0;
        }
        
        .activity-meta {
            font-size: 0.9rem;
            color: #666;
        }
        
        .auth-status {
            margin-top: 15px;
            padding: 10px;
            background: #e8f5e8;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .login-section {
            text-align: center;
            padding: 40px;
        }
        
        .login-section h2 {
            color: #2c3e50;
            margin-bottom: 20px;
        }
        
        @media (max-width: 768px) {
            .form-row {
                flex-direction: column;
            }
            
            .container {
                padding: 10px;
            }
            
            .auth-status {
                flex-direction: column;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📚 Canvas Course Shell Generator</h1>
            <p class="subtitle">Create multiple Canvas course shells quickly and efficiently</p>
            <div id="auth-status"></div>
        </header>
        
        <div class="card" id="main-content" style="display: none;">
            <h2>Create Course Shells</h2>
            <div id="status-message"></div>
            
            <form id="course-form">
                <div class="form-group">
                    <label for="account-select">Select Canvas Account:</label>
                    <select id="account-select" required>
                        <option value="">Loading accounts...</option>
                    </select>
                </div>
                
                <div id="shells-container">
                    <div class="shell-form">
                        <h3>Course Shell 1</h3>
                        <div class="form-row">
                            <div class="form-group">
                                <label>Course Name:</label>
                                <input type="text" class="course-name" required>
                            </div>
                            <div class="form-group">
                                <label>Course Code:</label>
                                <input type="text" class="course-code" required>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label>Start Date:</label>
                                <input type="date" class="start-date">
                            </div>
                            <div class="form-group">
                                <label>End Date:</label>
                                <input type="date" class="end-date">
                            </div>
                        </div>
                    </div>
                </div>
                
                <div style="margin: 20px 0; text-align: center;">
                    <button type="button" id="add-shell" class="button" style="background: #3498db;">Add Another Course</button>
                </div>
                
                <div style="text-align: center;">
                    <button type="submit" class="button">Create Course Shells</button>
                </div>
            </form>
        </div>
        
        <div class="card" id="activity-section" style="display: none;">
            <h2>Recent Activity</h2>
            <div id="activity-container">
                <div class="loading">Loading recent activity...</div>
            </div>
        </div>
        
        <div class="card" id="login-section">
            <div class="login-section">
                <h2>Authentication Required</h2>
                <p>Please log in with your Digital Promise Okta account to access the Canvas Course Shell Generator.</p>
                <div style="margin-top: 20px;">
                    <a href="/login" class="button">Login with Okta</a>
                </div>
            </div>
        </div>
    </div>

    <script>
        let shellCount = 1;
        let accounts = [];
        let currentUser = null;
        
        // Check authentication status
        async function checkAuth() {
            try {
                const response = await fetch('/api/user');
                if (response.ok) {
                    currentUser = await response.json();
                    showAuthenticatedContent();
                } else {
                    showLoginSection();
                }
            } catch (error) {
                console.error('Auth check error:', error);
                showLoginSection();
            }
        }
        
        // Show authenticated content
        function showAuthenticatedContent() {
            document.getElementById('login-section').style.display = 'none';
            document.getElementById('main-content').style.display = 'block';
            document.getElementById('activity-section').style.display = 'block';
            
            // Show user info
            document.getElementById('auth-status').innerHTML = `
                <div class="auth-status">
                    <span>Welcome, ${currentUser.firstName} ${currentUser.lastName} (${currentUser.email})</span>
                    <a href="/logout" class="button" style="background: #95a5a6; font-size: 14px; padding: 8px 16px;">Logout</a>
                </div>
            `;
            
            loadAccounts();
            loadRecentActivity();
        }
        
        // Show login section
        function showLoginSection() {
            document.getElementById('login-section').style.display = 'block';
            document.getElementById('main-content').style.display = 'none';
            document.getElementById('activity-section').style.display = 'none';
            document.getElementById('auth-status').innerHTML = '';
        }
        
        // Load Canvas accounts
        async function loadAccounts() {
            try {
                const response = await fetch('/api/accounts');
                if (!response.ok) throw new Error('Failed to load accounts');
                
                accounts = await response.json();
                const select = document.getElementById('account-select');
                select.innerHTML = '<option value="">Select an account...</option>';
                
                accounts.forEach(account => {
                    const option = document.createElement('option');
                    option.value = account.id;
                    option.textContent = account.name;
                    select.appendChild(option);
                });
            } catch (error) {
                console.error('Error loading accounts:', error);
                showMessage('Failed to load Canvas accounts', 'error');
            }
        }
        
        // Add new shell form
        document.getElementById('add-shell').addEventListener('click', function() {
            shellCount++;
            const container = document.getElementById('shells-container');
            const shellForm = document.createElement('div');
            shellForm.className = 'shell-form';
            shellForm.innerHTML = `
                <h3>Course Shell ${shellCount}</h3>
                <div class="form-row">
                    <div class="form-group">
                        <label>Course Name:</label>
                        <input type="text" class="course-name" required>
                    </div>
                    <div class="form-group">
                        <label>Course Code:</label>
                        <input type="text" class="course-code" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Start Date:</label>
                        <input type="date" class="start-date">
                    </div>
                    <div class="form-group">
                        <label>End Date:</label>
                        <input type="date" class="end-date">
                    </div>
                </div>
            `;
            container.appendChild(shellForm);
        });
        
        // Handle form submission
        document.getElementById('course-form').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const accountId = document.getElementById('account-select').value;
            if (!accountId) {
                showMessage('Please select a Canvas account', 'error');
                return;
            }
            
            // Collect shell data
            const shells = [];
            const shellForms = document.querySelectorAll('.shell-form');
            
            shellForms.forEach(form => {
                const name = form.querySelector('.course-name').value;
                const code = form.querySelector('.course-code').value;
                const startDate = form.querySelector('.start-date').value;
                const endDate = form.querySelector('.end-date').value;
                
                if (name && code) {
                    shells.push({
                        name,
                        courseCode: code,
                        accountId,
                        startDate: startDate || null,
                        endDate: endDate || null
                    });
                }
            });
            
            if (shells.length === 0) {
                showMessage('Please fill in at least one course shell', 'error');
                return;
            }
            
            // Show loading
            showMessage('Creating course shells...', 'loading');
            
            try {
                const response = await fetch('/api/course-shells', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ shells })
                });
                
                if (!response.ok) throw new Error('Failed to create course shells');
                
                const result = await response.json();
                showMessage(`Successfully created ${result.summary.completed} course shells. ${result.summary.failed} failed.`, 'success');
                
                // Reset form
                document.getElementById('course-form').reset();
                loadRecentActivity();
                
            } catch (error) {
                console.error('Error creating course shells:', error);
                showMessage('Failed to create course shells', 'error');
            }
        });
        
        // Show status message
        function showMessage(message, type) {
            const container = document.getElementById('status-message');
            container.innerHTML = `<div class="status-message ${type}">${message}</div>`;
            
            if (type === 'success') {
                setTimeout(() => {
                    container.innerHTML = '';
                }, 5000);
            }
        }
        
        // Load recent activity
        async function loadRecentActivity() {
            try {
                const response = await fetch('/api/recent-activity');
                if (!response.ok) throw new Error('Failed to load activity');
                
                const activities = await response.json();
                const container = document.getElementById('activity-container');
                
                if (activities.length === 0) {
                    container.innerHTML = '<p>No recent activity</p>';
                    return;
                }
                
                container.innerHTML = activities.map(activity => `
                    <div class="activity-item">
                        <strong>Batch ${activity.batch_id}</strong>
                        <div class="activity-meta">
                            ${activity.total_shells} shells | 
                            ${activity.completed_shells} completed | 
                            ${activity.failed_shells} failed | 
                            ${new Date(activity.created_at).toLocaleDateString()}
                        </div>
                    </div>
                `).join('');
                
            } catch (error) {
                console.error('Error loading activity:', error);
                document.getElementById('activity-container').innerHTML = '<p>Failed to load recent activity</p>';
            }
        }
        
        // Initialize
        checkAuth();
    </script>
</body>
</html>
EOF

# Set proper permissions
sudo chmod 644 /home/ubuntu/simple-course-shell-generator/public/index.html
sudo chown ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator/public/index.html

echo "Frontend updated successfully!"
echo "The full Canvas Course Shell Generator is now available at: https://shell.dpvils.org"