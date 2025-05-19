# Stage 1: build and install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies (if you have any C-extensions)
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

ENV PIP_ROOT_USER_ACTION=ignore


COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip install --prefix=/install -r requirements.txt

# Stage 2: final runtime image
FROM python:3.11-slim

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Copy installed packages
COPY --from=builder /install /usr/local

# Copy application code
COPY app /app
WORKDIR /app

# Use unbuffered logs (helps with Docker logging)
ENV PYTHONUNBUFFERED=1 \
    PORT=8000

# Expose port
EXPOSE 8000

# Drop to non-root user
USER appuser

# Run the app with Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
