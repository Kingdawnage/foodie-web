# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 as base
WORKDIR /app

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED 1

# todo: add here after adding supabase
ENV NEXT_PUBLIC_SUPABASE_URL=https://wtzgcdichgezejjnmzly.supabase.co
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0emdjZGljaGdlemVqam5temx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTkwNzg0NDMsImV4cCI6MjAzNDY1NDQ0M30.rl_KisHIVxHob9TXOGHej8gJPKdE0is2RSEEj6SrtN4
# RUN bun run test #todo: add here after adding tests
RUN bun run build

# copy production dependencies and source code into final image
FROM base AS release
WORKDIR /app

# Set correct permissions for nextjs user and don't run as root
RUN adduser crm
RUN chown crm:bun .
USER crm

COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease --chown=crm:bun /app/.next ./.next
COPY --from=prerelease /app/node_modules ./node_modules
COPY --from=prerelease /app/package.json ./package.json
COPY --from=prerelease /app/public ./public
CMD ["bun", "run", "build"]
# run the app
EXPOSE 3000/tcp
CMD ["bun", "start" ]