swagger: '2.0'
info:
  version: 1.0.0
  title: Payment Initiation API
  description: API for initiating payments and retrieving payment status/information under PSD2.
host: api.tbibank.bg
basePath: /tbibank-sb/psd2/v1/payments
schemes:
  - https
consumes:
  - application/json
produces:
  - application/json

securityDefinitions:
  oauth:
    type: oauth2
    description: OAuth2 Authentication
    flow: application
    tokenUrl: https://api.tbibank.bg/tbibank-sb/psd2/oauther/oauth2/token
    scopes:
      sandbox.PSP_PI: Initiate payments
  clientID:
    type: apiKey
    in: header
    name: X-IBM-Client-Id
  clientSecret:
    type: apiKey
    in: header
    name: X-IBM-Client-Secret

security:
  - clientID: []
    clientSecret: []
    oauth:
      - sandbox.PSP_PI

paths:
  /{payment-product}:
    post:
      summary: Payment Initiation Request
      description: |
        Used to initiate a payment at the ASPSP.
        Supported payment-products:
        - sepa-credit-transfers
        - cross-border-transfers
      operationId: initiatePayment
      parameters:
        - name: payment-product
          in: path
          description: The payment product to be used.
          required: true
          type: string
          enum: [sepa-credit-transfers, cross-border-transfers]
        
        # Headers
        - name: X-Request-ID
          in: header
          description: Unique ID of the request determined by the TPP.
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          description: The TLS certificate of the application.
          required: true
          type: string
        - name: PSU-IP-Address
          in: header
          description: IP Address of the PSU.
          required: true
          type: string
        - name: PSU-ID
          in: header
          description: Client ID of the PSU.
          required: true
          type: string
          
          # Optional Headers
        - name: Consent-ID
          in: header
          description: ID of the given consent for the PIS role.
          required: false
          type: string
        - name: PSU-IP-Port
          in: header
          description: IP Port of the PSU.
          required: false
          type: string
        - name: PSU-User-Agent
          in: header
          description: User Agent of the PSU.
          required: false
          type: string
        - name: PSU-Device-ID
          in: header
          description: Device ID of the PSU.
          required: false
          type: string
        - name: PSU-Geo-Location
          in: header
          description: Geo Location of the PSU.
          required: false
          type: string
        - name: TPP-Redirect-Preferred
          in: header
          description: Preference for redirect SCA.
          required: false
          type: boolean
        - name: TPP-Redirect-URI
          in: header
          description: URI for redirect after SCA.
          required: false
          type: string
        - name: TPP-Nok-Redirect-URI
          in: header
          description: URI for redirect after failed SCA.
          required: false
          type: string
        - name: Signature
          in: header
          description: Application level signature.
          required: false
          type: string
        - name: TPP-Signature-Certificate
          in: header
          description: Certificate used for signing.
          required: false
          type: string

        # Request Body
        - name: body
          in: body
          description: Payment initiation details
          required: true
          schema:
            $ref: '#/definitions/paymentInitiationRequest'

      responses:
        201:
          description: Created
          schema:
            $ref: '#/definitions/paymentInitiationResponse'
        400:
          description: Bad Request (Validation error)
        401:
          description: Unauthorized
        403:
          description: Forbidden
        404:
          description: Not Found
        405:
          description: Method Not Allowed
        429:
          description: Too Many Requests
        500:
          description: Internal Server Error
        503:
          description: Service Unavailable

  /{payment-product}/{paymentId}:
    get:
      summary: Get Payment Information
      description: Returns the content of a payment object.
      operationId: getPaymentInformation
      parameters:
        - name: payment-product
          in: path
          description: The payment product.
          required: true
          type: string
          enum: [sepa-credit-transfers, cross-border-transfers]
        - name: paymentId
          in: path
          description: ID of the payment initiation.
          required: true
          type: string
        
        # Headers
        - name: X-Request-ID
          in: header
          description: Unique ID of the request.
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          description: The TLS certificate.
          required: true
          type: string
        # Optional Headers (Subset of common headers)
        - name: PSU-ID
          in: header
          required: false
          type: string
        
      responses:
        200:
          description: OK
          schema:
            $ref: '#/definitions/paymentInitiationRequest' # Assuming returns same structure + status
        401:
          description: Unauthorized
        403:
          description: Forbidden
        404:
          description: Not Found

  /{payment-product}/{paymentId}/status:
    get:
      summary: Get Payment Status
      description: Check the transaction status of a payment initiation.
      operationId: getPaymentStatus
      parameters:
        - name: payment-product
          in: path
          description: The payment product.
          required: true
          type: string
          enum: [sepa-credit-transfers, cross-border-transfers]
        - name: paymentId
          in: path
          description: ID of the payment initiation.
          required: true
          type: string

        # Headers
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          required: true
          type: string

      responses:
        200:
          description: OK
          schema:
            type: object
            properties:
              transactionStatus:
                $ref: '#/definitions/transactionStatus'
              psuMessage:
                type: string
                description: Text to be displayed to the PSU
        401:
          description: Unauthorized
        403:
          description: Forbidden
        404:
          description: Not Found

definitions:
  # Primitive Models from Payment_Definitions
  amount:
    type: object
    required:
      - currency
      - amount
    properties:
      currency:
        type: string
        pattern: '[A-Z]{3}'
        description: ISO 4217 Alpha 3 currency code
        example: EUR
      amount:
        type: string
        description: Amount with fractional digits. Max 14 significant figures.
        example: "123.50"

  accountReference:
    type: object
    description: Account Reference
    properties:
      iban:
        type: string
        pattern: '[A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30}'
        example: BG94BANK12341234567890
      bban:
        type: string
        pattern: '[a-zA-Z0-9]{1,30}'
        example: BARC12345612345678
      pan:
        type: string
        maxLength: 35
        example: "5409050000000000"
      maskedPan:
        type: string
        maxLength: 35
        example: "123456xxxxxx1234"
      msisdn:
        type: string
        maxLength: 35
        example: "+898 898 888888"
      currency:
        type: string
        pattern: '[A-Z]{3}'
        example: EUR

  address:
    type: object
    description: Address Reference
    required: [country]
    properties:
      street:
        type: string
        maxLength: 70
        example: London Street
      buildingNumber:
        type: string
        example: "25"
      city:
        type: string
        example: Sofia
      postalCode:
        type: string
        example: "1000"
      country:
        type: string
        pattern: '[A-Z]{2}'
        example: BG

  transactionStatus:
    type: string
    description: "Payment Transaction Status Code. Possible values: ACCP, ACSC, PDNG, RJCT"
    enum: [ACCP, ACSC, PDNG, RJCT]

  # Composite Models
  paymentInitiationRequest:
    type: object
    description: Payment initiation instruction.
    required:
      - instructedAmount
      - creditorAccount
      - creditorName
    properties:
      endToEndIdentification:
        type: string
        maxLength: 35
        description: Unique transaction identification given by the payer
      debtorAccount:
        $ref: '#/definitions/accountReference'
      instructedAmount:
        $ref: '#/definitions/amount'
      creditorAccount:
        $ref: '#/definitions/accountReference'
      creditorAgent:
        type: string
        description: BICFI
        pattern: '[A-Z]{6,6}[A-Z2-9][A-NP-Z0-9]([A-Z0-9]{3,3}){0,1}'
      creditorName:
        type: string
        maxLength: 70
        description: Creditor Name
      creditorAddress:
        $ref: '#/definitions/address'
      remittanceInformationUnstructured:
        type: string
        maxLength: 140
        description: Payment reference
      serviceLevel:
        type: string
        enum: [SEPA, URGP, SDVA, NEXT, SPOT, INST]
        description: Service Level Code
      chargeBearer:
        type: string
        enum: [DEBT, CRED, SHAR, SLEV]
        description: Charge Bearer Code

  paymentInitiationResponse:
    type: object
    properties:
      transactionStatus:
        $ref: '#/definitions/transactionStatus'
      paymentId:
        type: string
        description: Resource identification of the generated payment initiation resource.
      transactionFees:
        $ref: '#/definitions/amount'
      currencyConversionFees:
        $ref: '#/definitions/amount'
      estimatedTotalAmount:
        $ref: '#/definitions/amount'
      scaMethods:
        type: array
        items:
          $ref: '#/definitions/authenticationObject'
      _links:
        type: object
        description: Hyperlinks for next steps (e.g. SCA redirect)

  authenticationObject:
    type: object
    properties:
      authenticationType:
        type: string
        enum: [SMS_OTP, CHIP_OTP, PHOTO_OTP, PUSH_OTP]
      authenticationMethodId:
        type: string
      name:
        type: string
        description: Name of the authentication method
