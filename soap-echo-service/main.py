import gzip
from fastapi import FastAPI, Request, Response
from lxml import etree
from io import BytesIO

app = FastAPI()

@app.post("/process")
async def process_xml(request: Request):
    # Read the incoming XML data from the request body
    xml_data = await request.body()

    try:
        # Parse the XML to ensure it's valid
        parsed_xml = etree.fromstring(xml_data)
    except etree.XMLSyntaxError as e:
        return Response(content=f"Invalid XML: {str(e)}", status_code=400)

    # Convert the XML back to binary format (echo part)
    response_data = etree.tostring(parsed_xml, xml_declaration=True, encoding='utf-8')

    # Compress the response data using gzip
    buffer = BytesIO()
    with gzip.GzipFile(fileobj=buffer, mode='wb') as gzip_file:
        gzip_file.write(response_data)

    compressed_data = buffer.getvalue()

    # Return the response with appropriate headers
    return Response(
        content=compressed_data,
        media_type="text/xml",
        headers={
            "Content-Encoding": "gzip",
            "Content-Length": str(len(compressed_data))
        }
    )

if __name__ == "__main__":
    # Run the FastAPI app using Uvicorn
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
