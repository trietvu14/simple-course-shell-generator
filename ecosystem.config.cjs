module.exports = {
  apps: [{
    name: 'canvas-course-generator',
    script: './dist/index.js',
    instances: 1,
    exec_mode: 'fork',
    env_file: '.env',
    env: {
      NODE_ENV: 'development',
      PORT: 5000,
      DATABASE_URL: process.env.DATABASE_URL,
      CANVAS_API_URL: process.env.CANVAS_API_URL,
      CANVAS_API_TOKEN: process.env.CANVAS_API_TOKEN
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000,
      DATABASE_URL: process.env.DATABASE_URL,
      CANVAS_API_URL: process.env.CANVAS_API_URL,
      CANVAS_API_TOKEN: process.env.CANVAS_API_TOKEN
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000
  }]
};