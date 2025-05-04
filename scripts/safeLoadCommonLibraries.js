const fs = require('fs');
const path = require('path');
const axios = require('axios');
require('dotenv').config();

const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;
if (!FHIR_SERVER_URL) {
  console.error("FHIR_SERVER_URL not set in .env");
  process.exit(1);
}

const commonLibDir = path.join(__dirname, '../common-libraries');

async function libraryExists(url, version) {
  try {
    const searchUrl = `${FHIR_SERVER_URL}/Library?url=${encodeURIComponent(url)}&version=${encodeURIComponent(version)}`;
    const res = await axios.get(searchUrl, {
      headers: { Accept: 'application/fhir+json' }
    });
    return res.data.total > 0;
  } catch (err) {
    console.error(`⚠️ Failed to check existence for ${url}|${version}:`, err.response?.data || err.message);
    return false;
  }
}

(async () => {
  const files = fs.readdirSync(commonLibDir).filter(f => f.endsWith('.json'));

  for (const file of files) {
    const fullPath = path.join(commonLibDir, file);
    const resource = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
    const { url, version } = resource;

    if (!url || !version) {
      console.warn(`⚠️ Skipping ${file}: missing url or version`);
      continue;
    }

    const exists = await libraryExists(url, version);
    if (exists) {
      console.log(`⏩ Skipped: ${file} (already exists: ${url}|${version})`);
      continue;
    }

    // Remove id before posting
    delete resource.id;

    try {
      const res = await axios.post(`${FHIR_SERVER_URL}/Library`, resource, {
        headers: { 'Content-Type': 'application/fhir+json' }
      });
      console.log(`✅ Uploaded: ${file} → ${res.data.id}`);
    } catch (err) {
      console.error(`❌ Failed to upload ${file}:`, err.response?.data || err.message);
    }
  }
})();