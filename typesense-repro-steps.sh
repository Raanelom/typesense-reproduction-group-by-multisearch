### Run Typesense via Docker ########################################
set -x

export TYPESENSE_API_KEY=xyz
export TYPESENSE_HOST=http://localhost:8108

docker stop typesense-repro 2>/dev/null
docker rm typesense-repro 2>/dev/null
rm -rf "$(pwd)"/typesense-data-dir-repro
mkdir "$(pwd)"/typesense-data-dir-repro

# Wait for Typesense to be ready
docker run -d -p 8108:8108 --name typesense-repro \
            -v"$(pwd)"/typesense-data-dir-repro:/data \
            typesense/typesense:30.0.rc27 \
            --data-dir /data \
            --api-key=$TYPESENSE_API_KEY \
            --enable-cors

# Wait till typesense is ready.
until curl -s -o /dev/null -w "%{http_code}" "$TYPESENSE_HOST/health" -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" | grep -q "200"; do
  sleep 2
done

curl -s "$TYPESENSE_HOST/debug" \
       -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" | jq


curl -s "$TYPESENSE_HOST/collections" \
       -X POST \
       -H "Content-Type: application/json" \
       -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
       -d '
          {
             "name": "companies",
             "fields": [
               {"name": "company_name", "type": "string" },
               {"name": "num_employees", "type": "int32" },
               {"name": "country", "type": "string", "facet": true }
             ],
             "default_sorting_field": "num_employees"
           }' | jq

curl -s "$TYPESENSE_HOST/collections" \
       -X POST \
       -H "Content-Type: application/json" \
       -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
       -d '
          {
             "name": "othercompanies",
             "fields": [
               {"name": "company_name", "type": "string" },
               {"name": "num_employees", "type": "int32" },
               {"name": "country", "type": "string", "facet": true }
             ],
             "default_sorting_field": "num_employees"
           }' | jq

curl -s "$TYPESENSE_HOST/collections/companies/documents/import?action=create" \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
        -H "Content-Type: text/plain" \
        -X POST \
        -d '{"id": "124","company_name": "Stark Industries","num_employees": 5215,"country": "USA"}
            {"id": "125","company_name": "Acme Corp","num_employees": 2133,"country": "CA"}
            {"id": "126","company_name": "Acme Corp 2","num_employees": 2132,"country": "CA"}'  | jq

curl -s "$TYPESENSE_HOST/collections/othercompanies/documents/import?action=create" \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
        -H "Content-Type: text/plain" \
        -X POST \
        -d '{"id": "124","company_name": "Stark Industries","num_employees": 5215,"country": "USA"}
            {"id": "125","company_name": "Acme Corp","num_employees": 2133,"country": "CA"}
            {"id": "124","company_name": "Stark Industries 2","num_employees": 5215,"country": "USA"}'  | jq

curl -s "$TYPESENSE_HOST/multi_search" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
        -d '
          {
            "union": true,
            "searches": [
              {
                "collection": "companies",
                "q": "corp",
                "query_by": "company_name",
                "group_by": "country",
                "group_limit": 1,
                "include_fields": "company_name"

              },
              {
                "collection": "othercompanies",
                "q": "stark",
                "query_by": "company_name",
                "group_by": "country",
                "group_limit": 1,
                "include_fields": "company_name"
              }
            ]
          }'  | jq

docker stop typesense-repro
docker rm typesense-repro

### Documentation ######################################################################################
# Visit the API reference section: https://typesense.org/docs/28.0/api/collections.html
# Click on the "Shell" tab under each API resource's docs, to get shell commands for other API endpoints