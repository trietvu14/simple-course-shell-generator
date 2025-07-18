// Test script to debug Canvas connection issues
import fetch from 'node-fetch';

async function testCanvasConnection() {
  console.log('Testing Canvas connection...');
  
  // Test 1: Login and get token
  console.log('\n1. Testing login...');
  const loginResponse = await fetch('http://localhost:5000/api/auth/simple-login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'DPVils25!' })
  });
  
  const loginData = await loginResponse.json();
  console.log('Login response:', loginData);
  
  if (!loginData.success) {
    console.error('Login failed!');
    return;
  }
  
  const token = loginData.token;
  
  // Test 2: Check Canvas OAuth status
  console.log('\n2. Testing Canvas OAuth status...');
  const statusResponse = await fetch('http://localhost:5000/api/canvas/oauth/status', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const statusData = await statusResponse.json();
  console.log('Status response:', statusData);
  
  // Test 3: Check environment variables
  console.log('\n3. Environment variables check:');
  console.log('CANVAS_CLIENT_ID:', process.env.CANVAS_CLIENT_ID ? 'Set' : 'Not set');
  console.log('CANVAS_CLIENT_SECRET:', process.env.CANVAS_CLIENT_SECRET ? 'Set' : 'Not set');
  console.log('CANVAS_API_URL:', process.env.CANVAS_API_URL || 'Not set');
  console.log('CANVAS_REDIRECT_URI:', process.env.CANVAS_REDIRECT_URI || 'Not set');
  
  // Test 4: Try to get Canvas accounts
  console.log('\n4. Testing Canvas accounts...');
  const accountsResponse = await fetch('http://localhost:5000/api/accounts', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const accountsData = await accountsResponse.json();
  console.log('Accounts response:', accountsData);
}

testCanvasConnection().catch(console.error);