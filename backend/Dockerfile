FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY pyproject.toml README.md requirements.lock ./
COPY src ./src
RUN python -m pip install --no-cache-dir --require-hashes -r requirements.lock \
    && python -m pip install --no-cache-dir --no-deps .

USER 65532:65532
EXPOSE 8000
CMD ["uvicorn", "memora.main:app", "--host", "0.0.0.0", "--port", "8000"]
