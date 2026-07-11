# --- Stage 1: Build dependencies ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Prevent Python from writing .pyc files and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies required for compiling some Python packages (e.g., psycopg2 for PostgreSQL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies into a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Ensure gunicorn is installed for production serving
RUN pip install --no-cache-dir gunicorn


# --- Stage 2: Final Runtime Image ---
FROM python:3.11-slim AS runner

WORKDIR /app

# Create a non-privileged user for security compliance (Never run containers as root!)
RUN useradd -u 8888 appuser

# Copy the pre-compiled virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application source code
COPY --chown=appuser:appuser . .

# Copy and prepare the startup entrypoint script
COPY --chown=appuser:appuser entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to the non-root user
USER appuser

# Expose Django's standard container port
EXPOSE 8000

# Hand off execution to our entrypoint script
ENTRYPOINT ["/entrypoint.sh"]