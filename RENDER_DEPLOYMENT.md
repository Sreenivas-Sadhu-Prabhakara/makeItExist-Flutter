# Render.com Deployment Guide for Make It Exist

This project is ready for unified deployment: Go backend and Flutter web frontend are served together from a single Docker container. Here’s how to deploy for free using Render.com.

---

## 1. Prerequisites
- GitHub account
- Render.com account ([https://render.com/](https://render.com/))

---

## 2. Step-by-Step Deployment (Render.com)

### A. Prepare Your Repo
1. Ensure all changes are committed and pushed to your main branch on GitHub.

### B. Deploy to Render.com
1. Go to [https://render.com/](https://render.com/) and sign in.
2. Click **New +** → **Web Service**.
3. Connect your GitHub repository.
4. For **Environment**, select **Docker**.
5. Render will auto-detect your Dockerfile and start building.
6. In the Render dashboard, go to the **Environment** tab and set environment variables:
   - `SERVER_PORT=8080`
   - `SERVER_ENV=production`
   - `JWT_SECRET=your-super-secret-key-change-this`
   - `AIM_EMAIL_DOMAIN=aim.edu`
   - `CORS_ALLOWED_ORIGINS=https://your-app.onrender.com`
   - (You will set DB variables in the next step)
7. Add a **PostgreSQL database** (Render provides a free Postgres database for small projects).
8. Copy the connection details from the database and set these variables:
   - `DB_HOST`
   - `DB_PORT`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_NAME`
   - `DB_SSLMODE=require`
9. Wait for the build and deployment to finish.
10. Visit your Render-provided URL to see your app live.

### C. (Optional) Custom Domain
- In Render, go to your service settings and add a custom domain if desired.

---

## 3. How It Works
- The Go server serves both the API and the Flutter web frontend from a single domain.
- PostgreSQL is managed by Render.
- No CORS issues, no need for separate frontend/backend deployments.

---

## 4. Troubleshooting
- If you see a database connection error, double-check your DB environment variables.
- If you need to reset the database, use the Render dashboard.
- For static file issues, ensure the Dockerfile copies the Flutter web build to `/app/static` and `FRONTEND_DIR` is set.

---

## 5. Local Development
- Use `docker-compose up --build` to run locally with Postgres and Go backend.
- The frontend is built and served by the Go server.

---

**Happy shipping!**
