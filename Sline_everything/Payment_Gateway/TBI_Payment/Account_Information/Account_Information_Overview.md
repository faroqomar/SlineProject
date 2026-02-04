swagger: "2.0"
info:
  title: Accounts
  x-ibm-name: accounts
  version: 1.0.0
  description: API for PSD2 Account Information Product
host: api.tbibank.bg
schemes:
  - https
basePath: /tbibank-sb/psd2/v1/accounts
produces:
  - application/json
consumes:
  - application/json
security:
  - clientID: []
    clientSecret: []
    oauth:
      - sandbox.PSP_AI
securityDefinitions:
  oauth:
    type: oauth2
    description: Oauth Authentication
    flow: application
    x-ibm-oauth-provider: oauther
    tokenUrl: /oauther/oauth2/token
    scopes:
      sandbox.PSP_AI: View account information
  clientSecret:
    type: apiKey
    description: Client Secret
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
    - url: https://api.tbibank.bg/tbibank-sb/psd2/v1/accounts
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
    get:
      operationId: getAccountList
      summary: Read Account List
      description: Read the identifiers of the available payment account together with booking balance information, depending on the consent granted.
      parameters:
        - name: X-Request-ID
          in: header
          required: true
          description: ID of the request, unique to the call.
          type: string
        - name: Consent-ID
          in: header
          required: true
          description: ID of the given consent.
          type: string
        - name: PSU-ID
          in: header
          required: true
          description: Client ID of the PSU.
          type: string
        - name: withBalance
          in: query
          required: false
          description: If true, include booking balance.
          type: boolean
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
          description: The TLS certificate of your application.
          type: string
      responses:
        "200":
          description: Successful response for Read Account List API.
          schema:
            $ref: "#/definitions/readAccountListResponse"
        "400":
          description: Bad Request
          schema:
             $ref: "#/definitions/BAD_REQUEST_400"
        "401":
          description: Unauthorized
          schema:
             $ref: "#/definitions/UNAUTHORIZED_401"
        "403":
           description: Forbidden
           schema:
             $ref: "#/definitions/FORBIDDEN_403"
  /{account-id}:
    get:
      operationId: getAccountDetails
      summary: Read Account Details
      description: Reads details about an account, with balances where required.
      parameters:
        - name: account-id
          in: path
          required: true
          description: The account identifier.
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: Consent-ID
          in: header
          required: true
          type: string
        - name: PSU-ID
          in: header
          required: true
          type: string
        - name: withBalance
          in: query
          required: false
          type: boolean
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
          description: Successful response.
          schema:
            $ref: "#/definitions/accountsDetailsReference"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
  /{account-id}/balances:
    get:
      operationId: getBalances
      summary: Read Account Balance
      description: Reads account data from a given account addressed by "account-id".
      parameters:
        - name: account-id
          in: path
          required: true
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: Consent-ID
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
          description: Successful response for Get Balances Service
          schema:
            $ref: "#/definitions/getBalancesResponse"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
  /{account-id}/transactions:
    get:
      operationId: getTransactionList
      summary: Read Transaction List
      description: Read transaction reports or transaction lists of a given account.
      parameters:
        - name: account-id
          in: path
          required: true
          type: string
        - name: dateFrom
          in: query
          required: false
          type: string
        - name: dateTo
          in: query
          required: false
          type: string
        - name: bookingStatus
          in: query
          required: true
          type: string
          enum: [booked, pending, both]
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: Consent-ID
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
          description: Successful response for Get Transaction List
          schema:
            $ref: "#/definitions/getTransactionListResponse"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
  /{account-id}/transactions/{resourceId}:
    get:
      operationId: getTransactionDetails
      summary: Read Transaction Details
      description: Reads transaction details from a given transaction.
      parameters:
        - name: account-id
          in: path
          required: true
          type: string
        - name: resourceId
          in: path
          required: true
          type: string
        - name: X-Request-ID
          in: header
          required: true
          type: string
        - name: Consent-ID
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
          description: Successful response for transaction details
          schema:
            $ref: "#/definitions/transactions"
        "400":
           description: Bad Request
           schema:
             $ref: "#/definitions/BAD_REQUEST_400"
definitions:
    readAccountListResponse:
      type: object
      properties:
        accounts:
          type: array
          items:
            $ref: "#/definitions/accountsDetailsReference"
      required:
        - accounts
    accountsDetailsReference:
      type: object
      properties:
        resourceId:
          type: string
        iban:
          $ref: "#/definitions/iban"
        bban:
          $ref: "#/definitions/bban"
        currency:
          $ref: "#/definitions/currency"
        name:
          type: string
        product:
          type: string
        cashAccountType:
          $ref: "#/definitions/cashAccountType"
        balances:
          type: array
          items:
            $ref: "#/definitions/balanceRef"
        _links:
            $ref: "#/definitions/_links"
      required:
        - currency
    getBalancesResponse:
      type: object
      properties:
        account:
          $ref: "#/definitions/account"
        balances:
          type: array
          items:
             $ref: "#/definitions/balanceRef"
      required: [balances]
    getTransactionListResponse:
      type: object
      properties:
        account:
           $ref: "#/definitions/account"
        transactions:
           $ref: "#/definitions/accountReport"
        balances:
           type: array
           items:
              $ref: "#/definitions/balanceRef"
        _links:
           $ref: "#/definitions/_links"
    accountReport:
      type: object
      properties:
        booked:
          type: array
          items:
            $ref: "#/definitions/transactions"
        pending:
          type: array
          items:
            $ref: "#/definitions/transactions"
        _links:
          $ref: "#/definitions/_links"
    transactions:
      type: object
      properties:
        transactionId:
          type: string
        entryReference:
          type: string
        bookingDate:
          type: string
          format: date
        valueDate:
           type: string
           format: date
        transactionAmount:
           $ref: "#/definitions/amountReference"
        creditorName:
           type: string
        debtorName:
           type: string
        remittanceInformationUnstructured:
            type: string
    balanceRef:
      type: object
      properties:
        balanceAmount:
          $ref: "#/definitions/amountReference"
        balanceType:
          $ref: "#/definitions/balanceType"
        referenceDate:
           type: string
           format: date
    amountReference:
      type: object
      properties:
        currency:
           $ref: "#/definitions/currency"
        amount:
           $ref: "#/definitions/amount"
    account:
      type: object
      properties:
        iban:
          $ref: "#/definitions/iban"
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
    amount:
       type: string
    cashAccountType:
       type: string
    balanceType:
       type: string
       enum: [closingBooked, expected, authorised, openingBooked, interimAvailable, forwardAvailable]
    _links:
      type: object
      additionalProperties: true
    BAD_REQUEST_400:
      type: object
      description: Bad Request
    UNAUTHORIZED_401:
      type: object
      description: Unauthorized
    FORBIDDEN_403:
      type: object
      description: Forbidden