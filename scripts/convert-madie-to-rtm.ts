#!/usr/bin/env tsx
/**
 * MADiE to Real-Time Mode Test Case Converter
 *
 * Converts MADiE test cases from future measurement periods to current/real-time compatible versions
 * - Rolls back all dates by specified years
 * - Generates new UUIDs for all resources
 * - Maintains referential integrity
 * - Preserves folder/file naming conventions
 */

import fs from "fs/promises";
import path from "path";
import { randomUUID } from "crypto";

interface TransformConfig {
  sourceDir: string;
  targetDir: string;
  yearOffset: number; // -1 to roll back one year
}

interface TestCase {
  patientId: string;
  folderPath: string;
  resources: Map<string, FHIRResource[]>; // resourceType -> resources
}

interface FHIRResource {
  resourceType: string;
  id: string;
  filePath: string;
  content: any;
}

class MADiEToRTMConverter {
  private uuidMap = new Map<string, string>();
  private referenceMap = new Map<string, string>();
  private processedFiles = new Set<string>();

  async convertTestSuite(config: TransformConfig): Promise<void> {
    console.log(`🚀 Starting MADiE → RTM conversion`);
    console.log(`Source: ${config.sourceDir}`);
    console.log(`Target: ${config.targetDir}`);
    console.log(`Year offset: ${config.yearOffset}\n`);

    // Phase 1: Discovery
    console.log("📁 Phase 1: Discovering test cases...");
    const testCases = await this.discoverTestCases(config.sourceDir);
    console.log(`Found ${testCases.length} test cases\n`);

    // Phase 2: Generate new UUIDs for all resources
    console.log("🔄 Phase 2: Generating new UUIDs...");
    this.generateUUIDs(testCases);
    console.log(`Generated ${this.uuidMap.size} new UUIDs\n`);

    // Phase 3: Transform each test case
    console.log("⚡ Phase 3: Transforming test cases...");
    await fs.mkdir(config.targetDir, { recursive: true });

    for (const testCase of testCases) {
      await this.transformTestCase(testCase, config);
    }

    console.log(`\n✅ Conversion complete!`);
    console.log(
      `Converted ${testCases.length} test cases to ${config.targetDir}`
    );
  }

  private async discoverTestCases(sourceDir: string): Promise<TestCase[]> {
    const testCases: TestCase[] = [];
    const entries = await fs.readdir(sourceDir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const patientId = entry.name;
        const testCasePath = path.join(sourceDir, patientId);

        console.log(`  📋 Discovering test case: ${patientId}`);
        const resources = await this.discoverResources(testCasePath);

        testCases.push({
          patientId,
          folderPath: testCasePath,
          resources,
        });
      }
    }

    return testCases;
  }

  private async discoverResources(
    testCasePath: string
  ): Promise<Map<string, FHIRResource[]>> {
    const resources = new Map<string, FHIRResource[]>();
    const entries = await fs.readdir(testCasePath, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const resourceType = entry.name;
        const resourceDir = path.join(testCasePath, resourceType);
        const resourceFiles = await fs.readdir(resourceDir);

        const resourceList: FHIRResource[] = [];
        for (const fileName of resourceFiles) {
          if (fileName.endsWith(".json")) {
            const filePath = path.join(resourceDir, fileName);
            const content = JSON.parse(await fs.readFile(filePath, "utf8"));

            resourceList.push({
              resourceType,
              id: content.id,
              filePath,
              content,
            });
          }
        }

        if (resourceList.length > 0) {
          resources.set(resourceType, resourceList);
        }
      }
    }

    return resources;
  }

  private generateUUIDs(testCases: TestCase[]): void {
    for (const testCase of testCases) {
      // Generate new UUID for the patient/test case folder
      const newPatientId = randomUUID();
      this.uuidMap.set(testCase.patientId, newPatientId);
      this.referenceMap.set(
        `Patient/${testCase.patientId}`,
        `Patient/${newPatientId}`
      );

      // Generate UUIDs for all resources
      for (const [resourceType, resources] of testCase.resources) {
        for (const resource of resources) {
          const newId = randomUUID();
          this.uuidMap.set(resource.id, newId);
          this.referenceMap.set(
            `${resourceType}/${resource.id}`,
            `${resourceType}/${newId}`
          );
        }
      }
    }
  }

  private async transformTestCase(
    testCase: TestCase,
    config: TransformConfig
  ): Promise<void> {
    const newPatientId = this.uuidMap.get(testCase.patientId)!;
    const newTestCaseDir = path.join(config.targetDir, newPatientId);

    console.log(`  🔄 Converting ${testCase.patientId} → ${newPatientId}`);

    await fs.mkdir(newTestCaseDir, { recursive: true });

    for (const [resourceType, resources] of testCase.resources) {
      const newResourceDir = path.join(newTestCaseDir, resourceType);
      await fs.mkdir(newResourceDir, { recursive: true });

      for (const resource of resources) {
        const transformedResource = this.transformResource(
          resource,
          config.yearOffset
        );
        const newId = this.uuidMap.get(resource.id)!;
        const newFilePath = path.join(newResourceDir, `${newId}.json`);

        await fs.writeFile(
          newFilePath,
          JSON.stringify(transformedResource, null, 2)
        );
      }
    }
  }

  private transformResource(resource: FHIRResource, yearOffset: number): any {
    // Deep clone the resource
    const transformed = JSON.parse(JSON.stringify(resource.content));

    // Update the resource ID
    const newId = this.uuidMap.get(resource.id)!;
    transformed.id = newId;

    // Apply temporal transformations
    this.rollBackDates(transformed, yearOffset);

    // Update all references
    this.updateReferences(transformed);

    return transformed;
  }

  private rollBackDates(obj: any, yearOffset: number): void {
    if (obj === null || typeof obj !== "object") return;

    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === "string" && this.isDateString(value)) {
        obj[key] = this.rollBackDateString(value, yearOffset);
      } else if (typeof value === "object") {
        this.rollBackDates(value, yearOffset);
      }
    }
  }

  private isDateString(str: string): boolean {
    // Match FHIR date/dateTime patterns
    const datePatterns = [
      /^\d{4}-\d{2}-\d{2}$/, // date: 2025-01-01
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, // dateTime: 2025-01-01T00:00:00
    ];

    return datePatterns.some((pattern) => pattern.test(str));
  }

  private rollBackDateString(dateStr: string, yearOffset: number): string {
    try {
      const date = new Date(dateStr);
      date.setFullYear(date.getFullYear() + yearOffset); // yearOffset is negative

      // Preserve original format
      if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
        return date.toISOString().split("T")[0];
      } else {
        // Preserve original datetime format
        const originalFormat = dateStr.includes("Z")
          ? dateStr
          : dateStr.replace("Z", "");
        return date.toISOString().substring(0, originalFormat.length);
      }
    } catch (error) {
      console.warn(`Failed to roll back date: ${dateStr}`);
      return dateStr;
    }
  }

  private updateReferences(obj: any): void {
    if (obj === null || typeof obj !== "object") return;

    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === "string" && this.isReference(value)) {
        const newReference = this.referenceMap.get(value);
        if (newReference) {
          obj[key] = newReference;
        }
      } else if (typeof value === "object") {
        this.updateReferences(value);
      }
    }
  }

  private isReference(str: string): boolean {
    // Match FHIR reference patterns: ResourceType/id
    return /^[A-Z][a-zA-Z]+\/[a-zA-Z0-9\-]+$/.test(str);
  }
}

// CLI execution
async function main() {
  const converter = new MADiEToRTMConverter();

  const config: TransformConfig = {
    // Commented source/targetes have been done.
    // sourceDir: '/Users/danheslinga/QI-Core-working-copies/CMS138-tobacco_0.2.000_working_copy/input/tests/measure/CMS138FHIRPreventiveTobaccoCessation',
    // targetDir: '/Users/danheslinga/QI-Core-working-copies/CMS138-tobacco_0.2.000_working_copy/input/tests/measure/CMS138FHIRPreventiveTobaccoCessation/test-realtime',
    sourceDir:
      "/Users/danheslinga/QI-Core-working-copies/CMS69-bmi_0.3.000_working_copy/input/tests/measure/CMS69FHIRPCSBMIScreenAndFollowUp",
    targetDir:
      "/Users/danheslinga/QI-Core-working-copies/CMS69-bmi_0.3.000_working_copy/input/tests/measure/CMS69FHIRPCSBMIScreenAndFollowUp/test-realtime",
    yearOffset: -1, // Roll back one year
  };

  try {
    await converter.convertTestSuite(config);
  } catch (error) {
    console.error("❌ Conversion failed:", error);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { MADiEToRTMConverter, type TransformConfig };
