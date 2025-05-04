const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");
const glob = require("glob");
require("dotenv").config();

const VSAC_API_KEY = process.env.VSAC_API_KEY;
const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;
// const MEASURE_DIR = process.argv.includes("--measure-dir")
//   ? process.argv[process.argv.indexOf("--measure-dir") + 1]
//   : process.env.MEASURE_DIR;
const MEASURE_DIR =
  process.argv.find(arg => arg.startsWith("--measure-dir="))?.split("=")[1] ||
  process.env.MEASURE_DIR;

if (!MEASURE_DIR) {
  console.error("❌ No --measure-dir argument or MEASURE_DIR in .env");
  process.exit(1);
}

const logFile = path.join(MEASURE_DIR, "vsacValueSetLoadLog.txt");
fs.appendFileSync(logFile, `\n📦 LOAD RUN @ ${new Date().toISOString()}\n`);

function extractValueSetUrisFromCQL(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  const regex = /valueset\s+\"[^\"]+\":\s+'([^']+)'/g;
  const uris = new Set();
  let match;
  while ((match = regex.exec(content)) !== null) {
    uris.add(match[1]);
  }
  return Array.from(uris);
}

function getAllCqlValueSetUris(measureDir) {
  const pattern = path.join(measureDir, "cql", "*.cql");
  const files = glob.sync(pattern);
  const uris = new Set();
  files.forEach((file) => {
    extractValueSetUrisFromCQL(file).forEach((uri) => uris.add(uri));
  });
  return Array.from(uris);
}

function extractOid(url) {
  return url.substring(url.lastIndexOf("/") + 1);
}

async function downloadValueSets(valueSets, overwriteExisting = false) {
  console.log(`Starting download of ${valueSets.length} ValueSets...`);
  const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox"] });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });

    await page.goto("https://cts.nlm.nih.gov/fhir/", { waitUntil: "networkidle2" });

    for (const url of valueSets) {
      const oid = extractOid(url);
      const outputPath = path.join("input", "vocabulary", "valueset", "external", `${oid}.json`);
      if (fs.existsSync(outputPath) && !overwriteExisting) {
        console.log(`⚠️ Already exists: ${outputPath}`);
        fs.appendFileSync(logFile, `⚠️ Already exists: ${url}\n`);
        continue;
      }

      try {
        const jsonUrl = `${url.replace("http://", "https://")}/$expand?_format=json`;
        console.log(`Downloading ${jsonUrl}`);
        const response = await page.goto(jsonUrl, { waitUntil: "networkidle2" });

        const jsonData = await page.evaluate(() => {
          const pre = document.querySelector("pre");
          return pre ? pre.textContent : document.body.innerText;
        });

        try {
          const parsed = JSON.parse(jsonData);
          if (parsed.resourceType === "ValueSet") {
            fs.writeFileSync(outputPath, JSON.stringify(parsed, null, 2));
            console.log(`✅ Saved: ${outputPath}`);
            fs.appendFileSync(logFile, `✅ Saved: ${url}\n`);
          } else {
            throw new Error("Invalid ValueSet structure");
          }
        } catch (parseErr) {
          console.error(`❌ Could not parse JSON for ${url}`);
          fs.appendFileSync(logFile, `❌ Parse error for ${url}: ${parseErr.message}\n`);
        }
      } catch (err) {
        console.error(`❌ ERROR downloading ${url}: ${err.message}`);
        fs.appendFileSync(logFile, `❌ ERROR for ${url}: ${err.message}\n`);
      }

      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  } finally {
    await browser.close();
  }

  console.log(`🧾 Log written to ${logFile}`);
}

async function main() {
  const valueSetUris = getAllCqlValueSetUris(MEASURE_DIR);
  if (!valueSetUris.length) {
    console.log("No ValueSets found in CQL files.");
    return;
  }
  await downloadValueSets(valueSetUris);
}

main();
