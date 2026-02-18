# 🚀 Deploying Make It Exist (Full Stack)

This project is ready for unified deployment: Go backend and Flutter web frontend are served together from a single Docker container. Here’s how to deploy for free using Railway.app (recommended for simplicity and free Postgres):

---

## 1. Prerequisites
- GitHub account
- Railway account ([https://railway.app/](https://railway.app/))

---

## 2. Step-by-Step Deployment (Railway)

### A. Prepare Your Repo
1. Ensure all changes are committed and pushed to your main branch on GitHub.

### B. Deploy to Railway
1. Go to [https://railway.app/](https://railway.app/) and sign in.
2. Click **New Project** → **Deploy from GitHub repo**.
3. Select your repository.
4. Railway will auto-detect your Dockerfile and start building.
5. In the Railway dashboard, go to the **Variables** tab and set environment variables:
   - `SERVER_PORT=8080`
   - `SERVER_ENV=production`
   - `JWT_SECRET=your-super-secret-key-change-this`
   - `AIM_EMAIL_DOMAIN=aim.edu`
   - `CORS_ALLOWED_ORIGINS=https://your-railway-url.up.railway.app`
   - (You will set DB variables in the next step)
6. Add a **PostgreSQL plugin** (Railway provides a free Postgres database).
7. Copy the connection details from the plugin and set these variables:
   - `DB_HOST`
   - `DB_PORT`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_NAME`
   - `DB_SSLMODE=require`
8. Wait for the build and deployment to finish.
9. Visit your Railway-provided URL to see your app live.

### C. (Optional) Custom Domain
- In Railway, go to your project settings and add a custom domain if desired.

---

## 3. How It Works
- The Go server serves both the API and the Flutter web frontend from a single domain.
- PostgreSQL is managed by Railway.
- No CORS issues, no need for separate frontend/backend deployments.

---

## 4. Troubleshooting
- If you see a database connection error, double-check your DB environment variables.
- If you need to reset the database, use the Railway dashboard.
- For static file issues, ensure the Dockerfile copies the Flutter web build to `/app/static` and `FRONTEND_DIR` is set.

---

## 5. Alternative Hosts
- You can use Render.com or Fly.io with the same Dockerfile and process.
- For Neon/Supabase Postgres, update the DB connection variables accordingly.

---

## 6. Local Development
- Use `docker-compose up --build` to run locally with Postgres and Go backend.
- The frontend is built and served by the Go server.

---

**Happy shipping!**
