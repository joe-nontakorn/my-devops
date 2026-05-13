# Use Bun image
FROM oven/bun:latest

# Set working directory
WORKDIR /app

# Copy files
COPY . .

# Install dependencies (if any)
RUN bun install

# Expose port (สมมติว่าเป็น 3000)
EXPOSE 3000

# Start application
CMD ["bun", "index.ts"]