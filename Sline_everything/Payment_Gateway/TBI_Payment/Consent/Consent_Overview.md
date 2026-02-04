swagger: "2.0"
info:
  title: Consents
  x-ibm-name: consents
  version: 1.0.0
  description: API for PSD2 Account Information Product
host: api.tbibank.bg
schemes:
  - https
basePath: /tbibank-sb/psd2/v1/consents
produces:
  - application/json
consumes:
  - application/json
security:
  - clientID: []
    clientSecret: []
    oauth:
      - sandbox.consents
securityDefinitions:
  oauth:
    type: oauth2
    description: Oauth Authentication
    flow: application
    x-ibm-oauth-provider: oauther
    tokenUrl: /oauther/oauth2/token
    scopes:
      sandbox.consents: Manage consents
  clientSecret:
    type: apiKey
    description: Client Secret used for authentication the APP
    name: X-IBM-Client-Secret
    in: header
  clientID:
    type: apiKey
    in: header
    name: X-IBM-Client-Id
x-ibm-configuration:
  phase: realized
  testable: true
  enforced: true
  cors:
    enabled: true
  application-authentication:
    certificate: true
  type: rest
  servers:
    - url: https://api.tbibank.bg/tbibank-sb/psd2/v1/consents
      description: ""
      type:
        - production
        - development
  oauth-servers:
    oauth:
      tokenUrls:
        - https://api.tbibank.bg/tbibank-sb/psd2/oauther/oauth2/token
      authorizationUrls: []
      refreshUrls: []
paths:
  /:
    post:
      operationId: createConsent
      summary: Create Consent
      description: This method create a consent resource, defining access rights to dedicated accounts of a given PSU-ID.
      parameters:
        - name: X-Request-ID
          in: header
          required: true
          description: ID of the request, unique to the call.
          type: string
        - name: PSU-ID
          in: header
          required: true
          type: string
        - name: body
          in: body
          required: true
          schema:
            $ref: "#/definitions/consentsPostRequest"
        - name: Date
          in: header
          required: true
          type: string
          default: "Sun, 28 Jan 2018 16:52:37 GMT"
        - name: Digest
          in: header
          required: false
          type: string
        - name: Signature
          in: header
          required: false
          type: string
        - name: TPP-Signature-Certificate
          in: header
          required: false
          type: string
        - name: X-Client-Certificate
          in: header
          required: true
          type: string
      responses:
        "201":
          description: Consent Created
          schema:
            $ref: "#/definitions/consentsResponse-201"
        "400":
          description: Bad Request
          schema:
             $ref: "#/definitions/BAD_REQUEST_400"
        "401":
          description: Unauthorized
          schema:
             $ref: "#/definitions/UNAUTHORIZED_401"
  /{consentId}:
    get:
      operationId: getConsent
      summary: Get Consent Request
      description: Returns the content of an account information consent object.
      parameters:
        - name: consentId
          in: path
          required: true
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: PSU-ID
          in: header
          required: true
          type: string
        - name: Date
          in: header
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          required: true
          type: string
      responses:
        "200":
          description: Successful response
          schema:
            $ref: "#/definitions/consentInformationResponse-200_json"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
    delete:
      operationId: deleteConsent
      summary: Delete Consent
      description: The TPP can delete an account information consent object if needed.
      parameters:
        - name: consentId
          in: path
          required: true
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: PSU-ID
          in: header
          required: true
          type: string
        - name: Date
          in: header
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          required: true
          type: string
      responses:
        "204":
          description: Consent Deleted
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
  /{consentId}/status:
    get:
      operationId: getConsentStatus
      summary: Consent Status Request
      description: Read the status of an account information consent resource.
      parameters:
        - name: consentId
          in: path
          required: true
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: PSU-ID
          in: header
          required: true
          type: string
        - name: Date
          in: header
          required: true
          type: string
        - name: X-Client-Certificate
          in: header
          required: true
          type: string
      responses:
        "200":
          description: Successful response
          schema:
            $ref: "#/definitions/consentStatusResponse-200"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
definitions:
  consentsPostRequest:
      properties:
        access:
          $ref: "#/definitions/accountAccess"
        recurringIndicator:
          $ref: "#/definitions/recurringIndicator"
        validUntil:
          $ref: "#/definitions/validUntil"
        frequencyPerDay:
          $ref: "#/definitions/frequencyPerDay"
        combinedServiceIndicator:
          $ref: "#/definitions/combinedServiceIndicator"
      required:
        - access
        - recurringIndicator
        - validUntil
        - frequencyPerDay
        - combinedServiceIndicator
  consentInformationResponse-200_json:
      properties:
        access:
          $ref: "#/definitions/accountAccess"
        recurringIndicator:
          $ref: "#/definitions/recurringIndicator"
        validUntil:
          $ref: "#/definitions/validUntil"
        frequencyPerDay:
          $ref: "#/definitions/frequencyPerDay"
        lastActionDate:
           $ref: "#/definitions/lastActionDate"
        consentStatus:
          $ref: "#/definitions/consentStatus"
        scaStatus:
           $ref: "#/definitions/scaStatus"
  consentStatusResponse-200:
       properties:
        consentStatus:
          $ref: "#/definitions/consentStatus"
        scaStatus:
          $ref: "#/definitions/scaStatus"
  consentsResponse-201:
      properties:
        consentStatus:
          $ref: "#/definitions/consentStatus"
        consentId:
          $ref: "#/definitions/consentId"
        scaMethods:
          $ref: "#/definitions/scaMethods"
        chosenScaMethod:
          $ref: "#/definitions/authenticationObject"
        challengeData:
          $ref: "#/definitions/challengeData"
        _links:
          $ref: "#/definitions/_links"
        psuMessage:
          $ref: "#/definitions/psuMessage"
  accountAccess:
      properties:
        accounts:
          type: array
          items:
            $ref: "#/definitions/account"
        balances:
          type: array
          items:
            $ref: "#/definitions/account"
        transactions:
          type: array
          items:
            $ref: "#/definitions/account"
        availableAccounts:
          type: string
          enum: [allAccounts, allAccountsWithBalances]
        allPsd2:
          type: string
          enum: [allAccounts]
  account:
      properties:
        iban:
          $ref: "#/definitions/iban"
        bban:
          $ref: "#/definitions/bban"
        currency:
          $ref: "#/definitions/currency"
  iban:
      type: string
      pattern: "[A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30}"
  bban:
       type: string
  pan:
       type: string
  maskedPan:
       type: string
  msisdn:
       type: string
  currency:
       type: string
       pattern: "[A-Z]{3}"
  recurringIndicator:
      type: boolean
  validUntil:
      type: string
      format: date
  frequencyPerDay:
      type: integer
  combinedServiceIndicator:
      type: boolean
  lastActionDate:
       type: string
       format: date
  consentStatus:
      type: string
      enum: [received, rejected, valid, revokedByPsu, expired, terminatedByTpp]
  consentId:
      type: string
  scaMethods:
      type: array
      items:
        $ref: "#/definitions/authenticationObject"
  authenticationObject:
       properties:
        authenticationType:
           $ref: "#/definitions/authenticationType"
        authenticationMethodId:
           $ref: "#/definitions/authenticationMethodId"
        name:
           type: string
  authenticationType:
       type: string
       enum: [SMS_OTP, CHIP_OTP, PHOTO_OTP, PUSH_OTP]
  authenticationMethodId:
       type: string
  challengeData:
       properties:
         image:
           type: string
         data:
           type: string
         imageLink:
           type: string
         otpMaxLength:
            type: integer
         otpFormat:
            type: string
  scaStatus:
      type: string
      enum: [received, psuIdentified, psuAuthenticated, scaMethodSelected, started, finalised, failed, exempted]
  psuMessage:
      type: string
  _links:
      type: object
  tppMessageCategory:
      type: string
      enum: [ERROR, WARNING]
  tppMessageText:
      type: string
  BAD_REQUEST_400:
      type: object
      description: Bad Request
  UNAUTHORIZED_401:
      type: object
      description: Unauthorized
  FORBIDDEN_403:
      type: object
      description: Forbidden