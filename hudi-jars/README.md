# Hudi JAR Files

This directory contains Hudi library dependencies required for Spark integration.

## Download Required

The `hudi-utilities-slim-bundle_2.12-0.15.0.jar` file (103 MB) is not included in the repository due to GitHub's 100 MB file size limit.

### Download Instructions

Run this command from the project root directory:

```bash
mkdir -p hudi-jars
wget https://repo.maven.apache.org/maven2/org/apache/hudi/hudi-utilities-slim-bundle_2.12/0.15.0/hudi-utilities-slim-bundle_2.12-0.15.0.jar \
  -O hudi-jars/hudi-utilities-slim-bundle_2.12-0.15.0.jar
```

Or with curl:

```bash
curl -o hudi-jars/hudi-utilities-slim-bundle_2.12-0.15.0.jar \
  https://repo.maven.apache.org/maven2/org/apache/hudi/hudi-utilities-slim-bundle_2.12/0.15.0/hudi-utilities-slim-bundle_2.12-0.15.0.jar
```

### Verify Download

```bash
ls -lh hudi-jars/hudi-utilities-slim-bundle_2.12-0.15.0.jar
```

Should show approximately 103 MB file size.
