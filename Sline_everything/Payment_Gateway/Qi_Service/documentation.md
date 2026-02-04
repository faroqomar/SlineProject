API Usage Guidelines
All integrations must adhere to the QiCard Terms and QiCard API Terms.

QiCard API Terms of Service
Introduction
This document explains the terms and conditions for using the QiCard API (referred to as "API"). By using the API, you agree to follow these terms. If you don’t agree, please don’t use the API.
Definitions
API: A set of tools and protocols provided by QiCard for accessing its services. User: Anyone who uses or accesses the API.
Service: The financial services offered by QiCard through the API.
License and Access
QiCard gives you a limited, non-exclusive, non-transferable license to use the API as outlined in these terms. You cannot sublicense, rent, lease, or resell access to the API.
Data Usage and Privacy
You must use the API legally and follow all relevant laws and regulations. You are responsible for protecting and maintaining the privacy of any data accessed or transmitted via the API, in line with QiCard's Privacy Policy and applicable data protection laws.
Security
You need to take reasonable steps to safeguard your API credentials and any data accessed through the API. Notify QiCard immediately if you become aware of any security breaches or unauthorized access.
Request Limitations and Usage
QiCard may set limits on how many API requests you can make within a certain timeframe. You agree not to exceed these limits, as doing so may lead to suspension or termination of your API access.
Fees and Payment
Using the API might involve fees, which will be outlined in a separate agreement. QiCard can change these fees at any time, but will provide prior notice of any changes.
Termination
QiCard can suspend or terminate your access to the API at any time, without notice, for any reason, including if you breach these terms.
Liability and Indemnification
QiCard is not liable for any damages resulting from your use of the API. You agree to protect and indemnify QiCard from any claims, damages, or costs that arise from your use of the API.
Intellectual Property
All intellectual property rights related to the API and its services belong to QiCard. You agree not to violate or misuse these intellectual property rights.
Modifications to Terms
QiCard can change these terms at any time. We will notify you of any changes, and continuing to use the API means you accept the updated terms.
Governing Law
These terms are governed by the laws of Jurisdiction, without considering its conflict of laws principles.
QiCard's public endpoints are built on the same technology as the core payment gateway platform. The QiCard engineering team closely monitors public API usage to ensure a high-quality experience for all users.

Below are the rate limits for a single integration (identified by client_id, not by access token) when using QiCard APIs. If you have any questions, please create a support ticket by selecting a relevant topic on the support page and Please provide detailed information, and we will contact you shortly.

API Rate Limits
The payment gateway presently does not enforce request limitations. However, this policy may be revised in the future.

Integrations that use QiCard’s API for creating payments and refunds must follow these guidelines. We reserve the right to modify or deprecate the APIs over time, but we will provide developers with ample notification. These notifications will be sent to the email address specified in your API settings.
API Features
This API provides methods for card payment transactions and related methods. Payment Gateway's team sets up the payment options and permissions on the Payment Gateway for each Merchant Terminal.

REST API
The QiCard Payment Gateway REST API allows the application to manage payment transactions on behalf of a QiCard Merchant. You can process payments, handle refunds and more...

Webhooks and Events
Webhooks allow your application to receive instant notifications after an event occurs in the QiCard Payment Gateway.

You can send transaction details to accounting right after a payment is processed, notify customers of payment status changes, sync customer information, and more, it's entirely up to you.
Integration Requirements
When calling the API, it is necessary to provide:

For methods that require authentication, it is necessary to pass the Merchant Terminal identifier (X-Terminal-Id) in the request header.

In each single invocation of the POST method, you need to provide a unique and unused ID as a (requestId). Data in requests must be encoded in UTF-8.

You must use SSL encryption with a key length of at least 128-bit.

Values of the fields of type Date are represented according to the format yyyy-MM-dd.

Values of the Date and time type are represented according to the format yyyy-MM-ddTHH:mm:ss, time according to the time zone GMT+3 in 24 hour format.

Values of the Amount type are represented according to the format 0.00 (two decimal places and a dot is used as a separator between the integer and the fractional part).
API Error Codes
1 - ORDER_ALREADY_EXISTS
2 - ORDER_NOT_FOUND
3 - ORDER_ALREADY_CANCELLED
4 - NO_COMPATIBLE_SERVICES_FOUND
5 - CAN_NOT_PROCESS_REQUEST
6 - REQUISITES_NOT_FOUND
7 - REQUISITES_ALREADY_EXISTS
8 - CAN_NOT_CREATE_NEW_REQUISITES
9 - TERMINAL_NOT_FOUND_EXCEPTION
10 - PAYMENT_ALREADY_EXISTS
11 - MAX_NUMBER_OF_PAYMENTS_FOR_ORDER_EXCEEDED
12 - PAYMENT_NOT_FOUND
13 - UNKNOWN_STRATEGY
14 - PROCESSING_IMPOSSIBLE
15 - CAN_NOT_CANCEL_PAYMENT
16 - CAN_NOT_CONFIRM_PAYMENT
17 - CAN_NOT_FINISH_AUTHENTICATION
18 - REFUNDS_NOT_ALLOWED
19 - PAYMENT_PARAMS_NOT_FOUND
20 - REFUND_ERROR
21 - VALIDATION_ERROR
22 - INCORRECT_PAYMENT_STATE
23 - INTERNAL_SYSTEM_ERROR
24 - EXTERNAL_SYSTEM_ERROR
26 - INVALID_PAYMENT_FORM_DOMAIN
27 - BAD_CREDENTIALS
28 - LIMIT_VIOLATION
29 - TRANSFER_NOT_FOUND
30 - INCORRECT_TRANSFER_STATE
31 - TOKEN_NOT_FOUND
32 - TOKEN_PROCESS_NOT_ALLOWED
33 - CAN_NOT_CANCEL_TRANSFER
34 - TRANSFER_ALREADY_EXISTS
35 - INVALID_TOKEN_TYPE
Basic Auth
Overview
This API uses Basic Authorization to authenticate clients. To access the API, clients must provide a valid username and password, which are encoded using Base64 and sent in the Authorization Header of each request.

Encoding Credentials in Base64
Basic Authentication requires encoding the username and password in the format:

username:password

This string must then be base64-encoded.

Usage Example
Assume your credentials are:

Username: client123

Password: secretpass

First, concatenate them with a colon:

client123:secretpass

Then, encode the string in Base64. The resulting encoded string would look something like:

Y2xpZW50MTIzOnNlY3JldHBhc3M=

Sending the Authentication Header
Once the credentials are encoded, include them in the Authorization header of your request.

A CURL example includes the Authorization Header:

curl --location '<PG_BASE_URL>/api/v1/payment/{PAYMENT_ID}/status' \
--header 'Authorization: Basic Y2xpZW50MTIzOnNlY3JldHBhc3M=' \
--header 'X-Terminal-Id: <TERMINAL_ID>' \

the example above explains how to include Basic Auth credentials in the GET Payment Status API endpoint.

Example: Basic Auth using JavaScript (Fetch API)
// e.g: for the following auth credentails.
// username: client123
// password: secretpass
// terminal ID: 111111
fetch('<PG_BASE_URL>/api/v1/payment/{PAYMENT_ID}/status', {
  method: 'GET',
  headers: {
    Authorization: 'Basic ' + btoa('client123:secretpass'),
    'X-Terminal-Id': '111111',
  },
})
  .then((response) => response.json())
  .then((data) => console.log(data));

Example: Basic Auth with Paython
import requests
from requests.auth import HTTPBasicAuth

url = "https://api.example.com/resource"
response = requests.get(url, auth=HTTPBasicAuth('client123', 'secretpass'))
print(response.json())

Important Notes
The Authorization header must be included in every request.
Never share your credentials with unauthorized users.
Conclusion
By following these steps, merchants can authenticate and securely access the API using Basic Authentication. For any issues, please contact Payment Gateway Support Team.
Signature-Based Authentication
To secure API communications, a digital signature is created using an RSA-2048 private key that is generated by the Payment Gateway. From this private key, a corresponding public key is derived. You must register this public key with the Payment Gateway, which then uses it to verify the authenticity of the signature on your API requests.

Here’s how we do it in simple terms:

Private Key Generation: The Payment Gateway creates a secret RSA-2048 private key. This private key is used to generate a digital signature for your API requests.

Public Key Creation: A matching public key is then generated from the private key. Unlike the private key, the public key can be shared.

Registration:: You need to send this public key to the Payment Gateway so that it can register it.

Verification: When you send an API request, the Payment Gateway uses the registered public key to verify the digital signature. This process ensures that the request is genuine and hasn’t been tampered with.

Example of generating a private key and converting it to DER format:

openssl genpkey -out rsakey.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
openssl rsa -in rsakey.pem -inform pem -out rsakey.der -outform der

Example of generating a public key based on private key in DER format:

openssl rsa -in rsakey.der -inform der -pubout -outform der -out rsapubkey.der

The signature must be passed in the HTTP request header with the name X-Signature, and the signature data must be encoded in Base64 format.

Signature String Format
The concatenation of request parameter strings is used as the data to be signed, converted to a byte representation using UTF-8 encoding. If the parameter value is missing or equals null, the - character is added to the string. The | character should be used as a separator between values.

Parameters should be concatenated in a strict order, also we should give attention to the following points:

The amount must have the number of digits after decimal point corresponding to the currency of the operation, for example if the currency is Iraqi dinar then the number of digits after the decimal point should be 3 digits.
The requestId parameter is always required for authentication by signature for each operation in the payment gateway.
Example of formatting a signature string
With the following payment creation request /payment for the terminalId = 012345:

{
  "requestId": "6b3d1423-644e-4ec7-92dd-b837e62294e4",
  "amount": 10,
  "withoutAuthenticate": true,
  "currency": "IQD",
  "paymentData": {
    "paymentType": "CARD",
    "pan": null,
    "expDate": "2505",
    "cvv": "000",
    "cardHolder": "JOHN DOE"
  }
}

The string for forming the signature will look like this:

012345|6b3d1423-644e-4ec7-92dd-b837e62294e4|10.000|IQD|true|-|-|-

The set of parameters for each payment operation
Depending on the type of operation, a different set of parameters is used to generate the signature, keep in mind, always follow the strict order of the parameters when concatenating the string:

createPayment /payment
terminalId
requestId
amount
currency
withoutAuthenticate
recurrent
paymentToken
getPaymentStatus /payment/{paymentId}/status
terminalId
requestId
paymentId
refundPayment /payment/{paymentId}/refund
terminalId
requestId
amount
paymentId
cancelPayment /payment/{paymentId}/cancel
terminalId
requestId
amount
paymentId
cancelPaymentByRequest /payment/cancel/by/request/{paymentRequestId}
terminalId
requestId
amount
paymentRequestId
refundPaymentByRequest /payment/refund/by/request/{paymentRequestId}
terminalId
requestId
amount
paymentRequestId
getPaymentStatusByRequest /payment/status/by/request/{paymentRequestId}
terminalId
requestId
paymentRequestId

Sandbox Environment
Welcome to the Sandbox Environment for our API. This environment allows you to test and integrate with our API using the provided credentials. Below are the details you need to get started.

Test Merchant Credentials
#  Basic Auth Credentials
Username: paymentgatewaytest
Password: WHaNFE5C3qlChqNbAzH4
# Test Terminal ID
X-Terminal-Id: 237984

These credentials are for testing purposes only and should not be used in a production environment.

Test Card
Use the following test card details to simulate transactions:

PAN (Card Number): 5213720304238582
CVV: 642
Expiration Date: 01-2032

Please note that these card details are only valid in the sandbox environment and will not work in a live setting.

API Host
Access the sandbox API using the following host link:

https://uat-sandbox-3ds-api.qi.iq/api/v1

Usage
Use the above credentials to authenticate your API requests.
Simulate transactions using the test card details.

Create Payment
Creates a Payment and returns the Payment object including formUrl (a payment link).

API Endpoint:
POST https://uat-sandbox-3ds-api.qi.iq/api/v1/payment

Headers
Name	Type	Description	Required
X-Terminal-Id	String	The ID of the Merchant Terminal. Provided by the Acquirer.	Yes
CURL Example
curl --location '<API_HOST>/api/v1/payment' \
--header 'X-Terminal-Id: {terminalId}' \
--header 'Authorization: Basic <Base64<username:password>>' \
--data '{
    "requestId": <GUID>,
    "amount": 1000.00,
    "locale": "en_US",
    "currency": "IQD",
    "finishPaymentUrl": "https://www.merchant.com/finish",
    "notificationUrl": "https://www.merchant.com/webhook-notification"
}'

Request Body
Media type: application/json
Example of a request body:

{
  "requestId": "37b85e60-e7a6-4abb-9466-703472fb83b9",
  "amount": 256.505,
  "currency": "IQD",
  "locale": "en_US",
  "finishPaymentUrl": "https://merchant.net/finish",
  "notificationUrl": "https://merchhant.net/notification",
  "customerInfo": {
    "firstName": "John",
    "middleName": "Mark",
    "lastName": "Doe",
    "phone": "009647xxxxxxxxx",
    "email": "j.doe@gmail.com",
    "accountId": "j.doe",
    "accountNumber": "40817123456787852369",
    "address": "57th street 26",
    "city": "Baghdad"
  },
  "additionalInfo": {
    "key1": "value1",
    "key2": "value2"
  }
}

Request body fields
Options	Type	Description
requestId	string required	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
amount	number required	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
currency	string required	The ISO 4217 code represents the currency for the payment, for example: IQD - Iraqi Dinar, The value must be exactly 3 characters long, Max value = 3, Min value = 3
locale	string optional	The locale for the payment form. If not specified, the default locale for the Merchant Terminal will be used..
fees	number optional	Merchant Fees, must have two decimels after point .
finishPaymentUrl	string required	This field specifies the URL where the payer will be redirected after the payment process is completed. The redirection occurs on the client side, and the URL is provided by the merchant. Once the payment is processed, the user is automatically sent to this URL, reflecting the outcome of the transaction, A merchant can use this field to redirect his user back to the merchant side, Maximum characters: 1024
notificationUrl	string required	This field is used to provide a webhook URL where the payment gateway will send a POST request to notify the merchant's side of the payment status after the payer completes the transaction. The notification will include in its body the updated data object of the payment (containing the new status: success, pending, or failure), allowing the merchant to track the result of the payment in real time
customerInfo	object optional	This object contains details about the customer making the payment and is optional for the merchant's side to include when using the create payment request. It helps the merchant track which customer is paying, offering visibility into their payments.
browserInfo	object optional	This field contains details about the browser where the payment is being made, provided by the merchant's side. While this field is optional, if included, certain fields within the browserInfo object are mandatory. When including this object in body request, if any of required fields are missing, the payment gateway will return a “bad request” response.
additionalInfo	object optional	Additional information about the payment.
Response Details
200 OK Response
when create payment succeed, you will receive the following payment object:

{
  "requestId": "4256ab83-de74-450f-b442-8fb995458243",
  "paymentId": "f2bb43a8-488a-4281-977b-5b3418fc3c67",
  "status": "CREATED",
  "canceled": false,
  "amount": 256.89,
  "currency": "IQD",
  "creationDate": "2024-08-04T15:34:33Z",
  "formUrl": "https://uat-sandbox-3ds-api.qi.iq/api/v1/payment/f2bb43a8-488a-4281-977b-5b3418fc3c67",
  "additionalInfo": {
    "key1": "value1",
    "key2": "value2"
  }
}


200 OK Response fields
Options	Type	Description
requestId	string	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
paymentId	string	Payment ID (Transaction ID): the payment transaction reference ID in the Payment Gateway system
status	string	the payment transaction status value, possible values are: SUCCESS, FAILED, CREATED & AUTHENTICATION_FAILED
canceled	boolean	A boolean value indicate if the payment got canceled or not.
amount	number	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
currency	string	The ISO 4217 code represents the currency for the payment, for example: IQD - Iraqi Dinar, The value must be exactly 3 characters long, Max value = 3, Min value = 3
creationDate	string	Payment object creation date, follows the ISO 8601 standard, example: '2024-08-04T15:34:33Z'.
formUrl	string	This object contains details about the customer making the payment and is optional for the merchant's side to include when using the create payment request. It helps the merchant track which customer is paying, offering visibility into their payments.
additionalInfo	object	Additional information about the payment.
400 Bad Request
{
  "error": {
    "code": 27,
    "description": "Authentication required: Incorrect credentials"
  }
}

500 Server Error
{
  "error": {
    "code": 23,
    "description": "INTERNAL_SYSTEM_ERROR"
  }
}

Possible Error Codes
1 - ORDER_ALREADY_EXISTS
2 - ORDER_NOT_FOUND
3 - ORDER_ALREADY_CANCELLED
4 - NO_COMPATIBLE_SERVICES_FOUND
5 - CAN_NOT_PROCESS_REQUEST
6 - REQUISITES_NOT_FOUND
7 - REQUISITES_ALREADY_EXISTS
8 - CAN_NOT_CREATE_NEW_REQUISITES
9 - TERMINAL_NOT_FOUND_EXCEPTION
10 - PAYMENT_ALREADY_EXISTS
11 - MAX_NUMBER_OF_PAYMENTS_FOR_ORDER_EXCEEDED
12 - PAYMENT_NOT_FOUND
13 - UNKNOWN_STRATEGY
14 - PROCESSING_IMPOSSIBLE
15 - CAN_NOT_CANCEL_PAYMENT
16 - CAN_NOT_CONFIRM_PAYMENT
17 - CAN_NOT_FINISH_AUTHENTICATION
18 - REFUNDS_NOT_ALLOWED
19 - PAYMENT_PARAMS_NOT_FOUND
20 - REFUND_ERROR
21 - VALIDATION_ERROR
22 - INCORRECT_PAYMENT_STATE
23 - INTERNAL_SYSTEM_ERROR
24 - EXTERNAL_SYSTEM_ERROR
26 - INVALID_PAYMENT_FORM_DOMAIN
27 - BAD_CREDENTIALS
28 - LIMIT_VIOLATION
29 - TRANSFER_NOT_FOUND
30 - INCORRECT_TRANSFER_STATE
31 - TOKEN_NOT_FOUND
32 - TOKEN_PROCESS_NOT_ALLOWED
33 - CAN_NOT_CANCEL_TRANSFER
34 - TRANSFER_ALREADY_EXISTS
35 - INVALID_TOKEN_TYPE


Refund Payment
Full or partial refund to the payer. In the case of a two-stage payment, a refund can be made after confirmation. The amount of all refunds must not exceed the amount of the payment.

API Endpoint:
POST https://uat-sandbox-3ds-api.qi.iq/api/v1/payment/{paymentId}/refund

Headers
Name	Type	Description	Required
X-Terminal-Id	String	The ID of the Merchant Terminal. Provided by the Acquirer.	Yes
Parameters
Name	Type	Description	Required
paymentId	String	the ID of the payment transaction that want to be refunded.	Yes
CURL Example
curl --location '<API_HOST>/api/v1/payment/{paymentId}/refund' \
--header 'X-Terminal-Id: {terminalId}' \
--header 'Authorization: Basic <Base64<username:password>>' \
--header 'Content-Type: application/json' \
--data '{
    "requestId": "20250301-231819-115",
    "amount": 10000.00,
    "message": "I want my money back :)"
}'

Request Body Example
Media type: application/json
Example of a request body:

{
  "requestId": "4256ab83-de74-450f-b442-8fb995458243",
  "amount": 52000.15,
  "message": "customer wants his money back :)",
  // optional object below
  "extParams": {
    "phone": "79997776655",
    "recipientBankId": "100000000001",
    "processRefundAsOct": true
  }
}

Request body fields
Options	Type	Description
requestId	string required	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
amount	number required	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
message	string optional	A string feild string can be used for example to document a reason why the user wants his money back.
extParams	object optional	optional additional data object
Response Details
200 OK Response
Refund Returned data:

{
  "refundId": "37b85e60-e7a6-4abb-9466-703472fb83b9",
  "requestId": "37b85e60-e7a6-4abb-9466-703472fb83b9",
  "paymentId": "37b85e60-e7a6-4abb-9466-703472fb83b9",
  "amount": 256.89,
  "status": "SUCCESS",
  "canceled": false,
  "currency": "IQD",
  "creationDate": "2020-05-14T12:06:39Z",
  "message": "Marriage",
  "details": {
    "resultCode": "00",
    "resultDescription": "Successfully",
    "rrn": "433726493310",
    "externalRrn": "123456789012",
    "authId": "39827334",
    "authDate": "2020-05-14T12:06:39Z",
    "maskedPan": "4234********3456",
    "paymentSystem": "VISA",
    "customDetails": {
      "octLimitBalance": "12345678.99"
    }
  }
}

200 OK Response fields
Options	Type	Description
refundId	string	A refund ID is used identify a refund object as a refrence for the refund operation, it can be used to fetch a refund details
requestId	string	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
paymentId	string	Payment ID (Transaction ID): the payment transaction reference ID in the Payment Gateway system
amount	number	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
status	string	the payment transaction status value, possible values are: SUCCESS, FAILED, CREATED & AUTHENTICATION_FAILED
canceled	boolean	A boolean value indicate if the payment got canceled or not.
currency	string	The ISO 4217 code represents the currency for the payment, for example: IQD - Iraqi Dinar, The value must be exactly 3 characters long, Max value = 3, Min value = 3
creationDate	string	Payment object creation date, follows the ISO 8601 standard, example: '2024-08-04T15:34:33Z'.
message	string	A string feild string can be used for example to document a reason why the user wants his money back.
details	object	additional info about the refund operation.
400 Bad Request
{
  "error": {
    "code": 27,
    "description": "Authentication required: Incorrect credentials"
  }
}

500 Server Error
{
  "error": {
    "code": 23,
    "description": "INTERNAL_SYSTEM_ERROR"
  }
}

Possible Error Codes
1 - ORDER_ALREADY_EXISTS
2 - ORDER_NOT_FOUND
3 - ORDER_ALREADY_CANCELLED
4 - NO_COMPATIBLE_SERVICES_FOUND
5 - CAN_NOT_PROCESS_REQUEST
6 - REQUISITES_NOT_FOUND
7 - REQUISITES_ALREADY_EXISTS
8 - CAN_NOT_CREATE_NEW_REQUISITES
9 - TERMINAL_NOT_FOUND_EXCEPTION
10 - PAYMENT_ALREADY_EXISTS
11 - MAX_NUMBER_OF_PAYMENTS_FOR_ORDER_EXCEEDED
12 - PAYMENT_NOT_FOUND
13 - UNKNOWN_STRATEGY
14 - PROCESSING_IMPOSSIBLE
15 - CAN_NOT_CANCEL_PAYMENT
16 - CAN_NOT_CONFIRM_PAYMENT
17 - CAN_NOT_FINISH_AUTHENTICATION
18 - REFUNDS_NOT_ALLOWED
19 - PAYMENT_PARAMS_NOT_FOUND
20 - REFUND_ERROR
21 - VALIDATION_ERROR
22 - INCORRECT_PAYMENT_STATE
23 - INTERNAL_SYSTEM_ERROR
24 - EXTERNAL_SYSTEM_ERROR
26 - INVALID_PAYMENT_FORM_DOMAIN
27 - BAD_CREDENTIALS
28 - LIMIT_VIOLATION
29 - TRANSFER_NOT_FOUND
30 - INCORRECT_TRANSFER_STATE
31 - TOKEN_NOT_FOUND
32 - TOKEN_PROCESS_NOT_ALLOWED
33 - CAN_NOT_CANCEL_TRANSFER
34 - TRANSFER_ALREADY_EXISTS
35 - INVALID_TOKEN_TYPE

Get Payment Status
retrieve a Payment object using Payment ID.

API Endpoint:
GET https://uat-sandbox-3ds-api.qi.iq/api/v1/payment/{paymentId}/status

Headers
Name	Type	Description	Required
X-Terminal-Id	String	The ID of the Merchant Terminal. Provided by the Acquirer.	Yes
Parameters
Name	Type	Description	Required
paymentId	String	the ID of the payment transaction that want to be refunded.	Yes
CURL Example
curl --location '<API_HOST>/api/v1/payment/{paymentId}/status' \
--header 'X-Terminal-Id: {terminalId}' \
--header 'Authorization: Basic <Base64<username:password>>' \

Response Details
200 OK Response
You will receive the following payment object:

{
  "requestId": "4256ab83-de74-450f-b442-8fb995458243",
  "paymentId": "f2bb43a8-488a-4281-977b-5b3418fc3c67",
  "status": "CREATED",
  "canceled": true,
  "amount": 5500.15,
  "currency": "IQD",
  "creationDate": "2024-08-04T15:34:33Z",
  "formUrl": "https://uat-sandbox-3ds-api.qi.iq/api/v1/payment/f2bb43a8-488a-4281-977b-5b3418fc3c67",
  "additionalInfo": {
    "key1": "value1"
  }
}


200 OK Response fields
Options	Type	Description
requestId	string	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
paymentId	string	Payment ID (Transaction ID): the payment transaction reference ID in the Payment Gateway system
status	string	the payment transaction status value, possible values are: SUCCESS, FAILED, CREATED & AUTHENTICATION_FAILED
canceled	boolean	A boolean value indicate if the payment got canceled or not.
amount	number	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
currency	string	The ISO 4217 code represents the currency for the payment, for example: IQD - Iraqi Dinar, The value must be exactly 3 characters long, Max value = 3, Min value = 3
creationDate	string	Payment object creation date, follows the ISO 8601 standard, example: '2024-08-04T15:34:33Z'.
formUrl	string	This object contains details about the customer making the payment and is optional for the merchant's side to include when using the create payment request. It helps the merchant track which customer is paying, offering visibility into their payments.
additionalInfo	object	Additional information about the payment.
400 Bad Request
{
  "error": {
    "code": 27,
    "description": "Authentication required: Incorrect credentials"
  }
}

500 Server Error
{
  "error": {
    "code": 23,
    "description": "INTERNAL_SYSTEM_ERROR"
  }
}

Cancel Payment
Cancellation Of The Payment. The payment can be canceled if it has not yet entered the processing stage or has been completed successfully and is awaiting confirmation.

API Endpoint:
POST https://uat-sandbox-3ds-api.qi.iq/api/v1/payment/{paymentId}/cancel

Headers
Name	Type	Description	Required
X-Terminal-Id	String	The ID of the Merchant Terminal. Provided by the Acquirer.	Yes
Parameters
Name	Type	Description	Required
paymentId	String	the ID of the payment transaction that want to be refunded.	Yes
CURL Example
curl --location '<API_HOST>/api/v1/payment/{paymentId}/cancel' \
--header 'X-Terminal-Id: {terminalId}' \
--header 'Authorization: Basic <Base64<username:password>>' \
--header 'Content-Type: application/json' \
--data '{
    "requestId": "f2bb43a8-488a-4281-977b-5b3418fc3c67"
}'

Request Body
Media type: application/json
Example of a request body:

{
  "requestId": "37b85e60-e7a6-4abb-9466-703472fb83b9"
}

Response Details
200 OK Response
You will receive the following payment object with the following response:

{
  "requestId": "20250302-002826-967",
  "paymentId": "15450bc8-6bd2-4be7-9254-7b9b3634eaf0",
  "status": "CREATED",
  "canceled": true,
  "amount": 1000.0,
  "currency": "IQD",
  "creationDate": "2025-03-02T00:28:27",
  "cancels": [
    {
      "requestId": "20250302-002847-182",
      "created": "2025-03-02T00:28:47",
      "successfully": true,
      "amount": 1000.0
    }
  ],
  "withoutAuthenticate": false,
  "additionalInfo": {}
}

200 OK Response fields
Options	Type	Description
requestId	string	A unique identifier generated by the Merchant's side. It must be ensured that the RequestId remains unique within the context of each Merchant Terminal to prevent duplication or conflicts.
paymentId	string	Payment ID (Transaction ID): the payment transaction reference ID in the Payment Gateway system
status	string	the payment transaction status value, possible values are: SUCCESS, FAILED, CREATED & AUTHENTICATION_FAILED
canceled	boolean	A boolean value indicate if the payment got canceled or not.
amount	number	Specifies the total payment amount, including any applicable fees or commissions from the merchant. This field is required for all payment transactions but should be absent for non-payment transactions. Note non-payment transactions are used to collect card information without processing any payment. This type of transaction is useful when card details are needed for future use, but no immediate charge is required.
currency	string	The ISO 4217 code represents the currency for the payment, for example: IQD - Iraqi Dinar, The value must be exactly 3 characters long, Max value = 3, Min value = 3
creationDate	string	Payment object creation date, follows the ISO 8601 standard, example: '2024-08-04T15:34:33Z'.
cancels	Array[object]	This object contains details about the customer making the payment and is optional for the merchant's side to include when using the create payment request. It helps the merchant track which customer is paying, offering visibility into their payments.
withoutAuthenticate	boolean	If value is false, then the 3DS challage is enabled.
additionalInfo	object	Additional information about the payment.
400 Bad Request
{
  "error": {
    "code": 27,
    "description": "Authentication required: Incorrect credentials"
  }
}

500 Server Error
{
  "error": {
    "code": 23,
    "description": "INTERNAL_SYSTEM_ERROR"
  }
}
Enable Webhooks
Enable Webhooks Notifications with The Payment Gateway
The steps needed to enable Payment Gateway webhook notifications:

In POST /payment request (the request we use to create payments), there is a field named notificationUrl, you have to provide your webhook URL in that field to receive webhook messages on it.

Your provided webhook URL should be publicly available and reachable on the public internet network, It should also be HTTPS; HTTP URL without an SSL certificate will not be acceptable.

When receiving a webhook message from our Payment Gateway, you will receive a payment object containing all the needed information about that particular payment including the new payment status,when doing processing on that received payment object, you should always return a 200 OK response to our Payment Gateway otherwise the payment gateway to repeat sending that particular webhook message. Note: when your system (The merchant application) receives a webhook request from our Payment Gateway, you must respond to our webhook with a 200 OK response otherwise our Payment Gateway will keep sending you new repeated webhook messages for that particular payment.

Tip About Webhooks
the Merchant application should respond with 200 OK, otherwise, the Payment Gateway will keep sending webhook requests repeatedly.

Webhook Data Sample
Received Request Header
{
   "X-Signature": "R/sDfOilPfSNB7oqIF/Vgil3bcECQaHVlQ57nK20mzY65Sr9fZDQrJabVTbS7ILFRshXTASGOfF
   t0n8WkdDOtCEZ3phYISIg4PZ4RpCzN5thqUn1cblthUTo919wCzVnJEVtFs4qqmfl+DFrHkRAjbSkbepcXuG0HymRPI
   oK26YSBQyPl9WUVLJ9h9dJ8lktspDqxDjb2cgk1jsckiXZkrAVDTh28R/h51yTUJpx6M9rIHWJtVgMxZS7nl45DBuOT
   qwJxyKQftwOQpbrN19wtCpzRPys3zFFnwAzlLa6hOThIaszyMgkuxtSfuRvIRC2PALBz+1aFBpQn0Yg7v7bFg=="
}


Signature Verification
If you want to verify the X-Signature, you will need to acquire Payment Gateway's RSA Public key, Contact the Payment Gateway Team to request it.

Received Request Body
You will receive the following request payload on the webhook URL (notificationUrl), it contains the full payment object including the status & paymentId fields, use these fields to update the Order or Payment status on your system (Merchant system).

{
  "requestId": "20250226-171349-023",
  "paymentId": "935e93e1-c74b-45ac-8e95-e11e817eb48f",
  "status": "SUCCESS",
  "canceled": false,
  "amount": 3000,
  "confirmedAmount": 3000,
  "currency": "IQD",
  "paymentType": "CARD",
  "creationDate": "2025-02-26T17:13:51",
  "details": {
    "resultCode": "00",
    "rrn": "505700009817",
    "authId": "123456",
    "authDate": "2025-02-26T17:21:06",
    "maskedPan": "521372******8582",
    "paymentSystem": "MASTER_CARD"
  },
  "withoutAuthenticate": false,
  "additionalInfo": {}
}Webhook Verification
Webhook Verification Implementation
This document outlines the implementation of the webhook verification mechanism on the merchant system. It describes how to verify webhook messages received from the Payment Gateway by using RSA signature verification to ensure data integrity and authenticity.

Overview
When a webhook is sent from the Payment Gateway, it includes a header X-Signature containing a base64-encoded RSA signature. This signature is generated using the Payment Gateway’s private key. The merchant system verifies the webhook by reconstructing a data string from the payload and using the previously obtained public key to validate the signature. If the verification succeeds, the webhook is deemed authentic and can be processed securely.

Prerequisites
Public Key: The merchant must first obtain the Payment Gateway's public key in PEM format. This key is used during the verification process. you can request The Payment Gateway Public Key by contacting the Payment Gateway Support

Dev Environment: The provided implementation example uses Node.js modules such as crypto, fs, and path.

Payment Gateway Specifications: Follow the Payment Gateway documentation for any additional guidelines regarding webhook format and signature generation.

Webhook Payload and Signature
Example Webhook Payload
The webhook payload is a JSON object that includes essential payment details. For instance:

{
  "requestId": "20250113-212519-073",
  "paymentId": "b91e8d70-1ab7-4275-85a2-61f7dbb31410",
  "status": "SUCCESS",
  "amount": 10000,
  "currency": "IQD",
  "creationDate": "2025-01-13T21:25:19"
}

X-Signature Header
Along with the payload, the webhook request includes an X-Signature header. This header carries a base64-encoded RSA signature that is used to verify the authenticity of the payload.

Signature Verification Process
The verification process involves two main steps:

Step 1: Data Preparation
A specific data string is constructed by concatenating selected fields from the payload. The process is as follows:

Payment ID: Directly used (or a placeholder if missing).
Amount: Converted to a string with a .000 suffix to represent the formatted amount.
Currency: Directly used.
Creation Date: Directly used.
Status: Directly used.
Each field is separated by the pipe | character. For example, for the payload above, the resulting data string would be:

b91e8d70-1ab7-4275-85a2-61f7dbb31410|10000.000|IQD|2025-01-13T21:25:19|SUCCESS

Step 2: Signature Verification
The verification is performed using the RSA SHA256 algorithm:

Decode the Signature: Convert the base64-encoded signature into a buffer.

Create a Verifier: Utilize Node.js crypto module to create a verifier with the sha256 algorithm.

Update the Verifier: Provide the verifier with the constructed data string.

Verify the Signature: Compare the decoded signature against the data string using the public key.

If the signature is valid, the webhook is considered authentic.

Code Example
Below is the complete Node.js code implementing the webhook verification:

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Import the Payment Gateway public key (.PEM format)
const publicKey = fs.readFileSync(path.join('public-key.pem'), 'utf8');

// Example of received payload from the webhook message
const requestPayload = {
  requestId: '20250113-212519-073',
  paymentId: 'b91e8d70-1ab7-4275-85a2-61f7dbb31410',
  status: 'SUCCESS',
  amount: 10000,
  currency: 'IQD',
  creationDate: '2025-01-13T21:25:19',
};

// Received X-Signature from request headers
const receivedSignature = `<Request_X_Signature>`;

// Step 1: Prepare the data segments for signature verification
const fields = [
  requestPayload.paymentId || '-',
  requestPayload.amount ? requestPayload.amount.toString() + '.000' : '-',
  requestPayload.currency || '-',
  requestPayload.creationDate || '-',
  requestPayload.status || '-',
];

// Join data segments with the symbol "|" to create a single string
const dataString = fields.join('|');

// Step 2: Verify the signature
function verifySignature(data, signature, publicKey) {
  const signatureBuffer = Buffer.from(signature, 'base64');
  const verifier = crypto.createVerify('sha256');
  verifier.update(data);
  verifier.end();
  return verifier.verify(publicKey, signatureBuffer);
}

const isValid = verifySignature(dataString, receivedSignature, publicKey);

if (isValid) {
  console.log('Signature is valid.');
} else {
  console.log('Signature is invalid.');
}

Best Practices
Secure Storage: Ensure the public key is stored securely and is not exposed to unauthorized parties.

Error Handling: Implement robust error handling to manage scenarios where the signature verification fails. Logging: Maintain logs for both successful and failed verification attempts to assist in monitoring and debugging.

Data Consistency: Verify that the webhook payload structure is consistent with expectations; any deviation may result in a failed signature verification.

Conclusion
By implementing RSA signature verification as described, the merchant system can securely validate that the webhooks received from the Payment Gateway are authentic and untampered. This process significantly enhances the security of the payment processing workflow. For additional details or troubleshooting, please refer to the Payment Gateway’s official documentation or contact their support team.

Flutter Integration
Flutter Integration using Dart Wrapper
Create a Dart class that uses MethodChannel to communicate with the native implementations.

import 'package:flutter/services.dart';

class PaymentSDK {
  static const MethodChannel _channel = MethodChannel('payment_sdk');

  /// Initialize the Payment SDK with the given configuration
  static Future<void> initialize(Map<String, dynamic> config) async {
    await _channel.invokeMethod('initialize', config);
  }

  /// Update the Payment SDK configuration dynamically
  static Future<void> updateConfiguration(Map<String, dynamic> config) async {
    await _channel.invokeMethod('updateConfiguration', config);
  }

  /// Process a payment with the given details
  static Future<String> processPayment(Map<String, dynamic> paymentDetails) async {
    return await _channel.invokeMethod('processPayment', paymentDetails);
  }

  /// Retrieve payment tokens associated with an account ID
  static Future<List<dynamic>> getPaymentTokens(String accountId) async {
    return await _channel.invokeMethod('getPaymentTokens', {'accountId': accountId});
  }

  /// Retrieve the latest token transactions for a specific payment token
  static Future<List<dynamic>> getLatestTokenTransactions(String paymentToken) async {
    return await _channel.invokeMethod(
      'getLatestTokenTransactions',
      {'paymentToken': paymentToken},
    );
  }

  /// Block a specific payment token
  static Future<void> blockPaymentToken(String paymentToken) async {
    await _channel.invokeMethod('blockPaymentToken', {'paymentToken': paymentToken});
  }

  /// Transfer payment tokens to another device for the same account ID
  static Future<void> transferPaymentTokens(String accountId, List<String> tokens) async {
    await _channel.invokeMethod('transferPaymentTokens', {
      'accountId': accountId,
      'tokens': tokens,
    });
  }

  /// Set connection settings for the payment gateway
  static Future<void> setConnectionSettings(Map<String, dynamic> settings) async {
    await _channel.invokeMethod('setConnectionSettings', settings);
  }

  /// Subscribe to the payment form closure event
  static Future<void> onPaymentFormClosed() async {
    await _channel.invokeMethod('onPaymentFormClosed');
  }

  /// Handle SDK exceptions such as SDKNotInitializedException
  static Future<void> handleSDKExceptions() async {
    await _channel.invokeMethod('handleSDKExceptions');
  }
}

Usage Example
Usage of the Payment SDK in a Flutter application:

import 'package:your_app/payment_sdk.dart';

void main() async {
  final config = {
    'language': 'en',
    'theme': 'light',
    'baseUrl': 'https://api.qicardpaymentgateway.com',
  };

  await PaymentSDK.initialize(config);

  final paymentDetails = {
    'paymentId': '123456',
    'amount': 101.90,
    'currency': 'GBP',
    'customerInfo': {
      'accountId': 'user_001',
    },
    'paymentMethod': {
      'paymentType': 'PAYMENT_TOKEN',
      'paymentToken': 'abc123',
    },
  };

  try {
    final result = await PaymentSDK.processPayment(paymentDetails);
    print('Payment Successful: $result');
  } catch (error) {
    print('Payment Failed: $error');
  }
}