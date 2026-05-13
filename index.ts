const server = Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello from CI/CD on K3s! 🚀");
  },
});

console.log(`Listening on http://localhost:${server.port}`);