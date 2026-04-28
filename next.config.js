/** Rob 20260427 - Updated the Next.js configuration to enable static export, allowing the application to be deployed as a static site. This change is essential for hosting on platforms that do not support server-side rendering. */

/**
 * @type {import('next').NextConfig}
 */
const nextConfig = {
  output: 'export',
}

module.exports = nextConfig