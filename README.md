# Kong Custom Plugin

**Description: This is a plugin to transform a SOAP response's XML values to a new value**

## Installing Custom Plugin - DB

```sh
docker-compose up -d
```

#### To rebuild an image after making changes to soap-custom-service etc

```sh
docker-compose down
docker-compose up --build
```

- Add a service

```sh
http POST http://localhost:8001/services name=example-service url=http://soapechoservice:8080/process
```

- Add a Route to the Service

```sh
http POST http://localhost:8001/services/example-service/routes name=example-route paths:='["/echo"]'
```

- Add Plugin to the Service

```sh
http -f http://localhost:8001/services/example-service/plugins name=myplugin
```

### Test

**1. Go to SoapUI and add the `/soap-request/request.xml` payload into the request body**

**2. Verify all `<ChannelType>DigitalAPI</ChannelType>` is changed to `<ChannelType>API</ChannelType>` instead in the echo-ed response**

- This is because the server only echoes a response
- Plugin (myplugin) will transform the results to the new value as per the logic
