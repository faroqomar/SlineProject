Overview
API for PSD2 Confirmation of Funds Product

Type
REST 
OAS2
Protocol
HTTPS
Endpoint
Production, Development:
https://api.tbibank.bg/tbibank-sb/psd2/v1/funds-confirmations
Security
Mutual TLS
Enabled
clientID
X-IBM-Client-Id
apiKey located in header
clientSecret
X-IBM-Client-Secret
apiKey located in header
oauth
Type
oauth2
Security flow
application
Token URLs
https://api.tbibank.bg/tbibank-sb/psd2/oauther/oauth2/token
Scopes
sandbox.PSP_IC - Confirm funds availability
Oauth Authentication

{
  "swagger": "2.0",
  "info": {
    "title": "Funds",
    "x-ibm-name": "funds",
    "version": "1.0.0",
    "description": "API for PSD2 Confirmation of Funds Product"
  },
  "host": "api.tbibank.bg",
  "schemes": [
    "https"
  ],
  "basePath": "/tbibank-sb/psd2/v1/funds-confirmations",
  "produces": [
    "application/json"
  ],
  "consumes": [
    "application/json"
  ],
  "security": [
    {
      "clientID": [],
      "clientSecret": [],
      "oauth": [
        "sandbox.PSP_IC"
      ]
    }
  ],
  "securityDefinitions": {
    "oauth": {
      "type": "oauth2",
      "description": "Oauth Authentication",
      "flow": "application",
      "x-ibm-oauth-provider": "oauther",
      "tokenUrl": "/oauther/oauth2/token",
      "scopes": {
        "sandbox.PSP_IC": "Confirm funds availability"
      }
    },
    "clientSecret": {
      "type": "apiKey",
      "name": "X-IBM-Client-Secret",
      "in": "header"
    },
    "clientID": {
      "type": "apiKey",
      "name": "X-IBM-Client-Id",
      "in": "header"
    }
  },
  "x-ibm-configuration": {
    "phase": "realized",
    "testable": true,
    "enforced": true,
    "cors": {
      "enabled": true
    },
    "application-authentication": {
      "certificate": true
    },
    "type": "rest",
    "servers": [
      {
        "url": "https://api.tbibank.bg/tbibank-sb/psd2/v1/funds-confirmations",
        "description": "",
        "type": [
          "production",
          "development"
        ]
      }
    ],
    "oauth-servers": {
      "oauth": {
        "tokenUrls": [
          "https://api.tbibank.bg/tbibank-sb/psd2/oauther/oauth2/token"
        ],
        "authorizationUrls": [],
        "refreshUrls": []
      }
    }
  },
  "definitions": {
    "amountReference": {
      "type": "object",
      "additionalProperties": false,
      "description": "Amount Reference",
      "properties": {
        "currency": {
          "$ref": "#/definitions/currency"
        },
        "amount": {
          "$ref": "#/definitions/amount"
        }
      }
    },
    "confirmationOfFundsResponseSuccess": {
      "type": "object",
      "description": "Successfull JSON Response body for the \"Confirmation of Funds Service\"",
      "additionalProperties": false,
      "properties": {
        "fundsAvailable": {
          "$ref": "#/definitions/fundsAvailable"
        }
      }
    },
    "confirmationOfFundsRequest": {
      "type": "object",
      "description": "JSON Request body for the \"Confirmation of Funds Service\"",
      "additionalProperties": false,
      "properties": {
        "cardNumber": {
          "$ref": "#/definitions/cardNumber"
        },
        "account": {
          "$ref": "#/definitions/account"
        },
        "payee": {
          "$ref": "#/definitions/payee"
        },
        "instructedAmount": {
          "$ref": "#/definitions/amountReference"
        }
      },
      "required": [
        "account",
        "instructedAmount"
      ],
      "example": {
        "account": {
          "iban": "BG94BANK12341234567890"
        },
        "instructedAmount": {
          "currency": "BGN",
          "amount": "123.50"
        }
      }
    },
    "cardNumber": {
      "type": "string",
      "description": "Card Number of the card issued by the PIISP. Should be delivered if available.",
      "example": "12345678901234"
    },
    "account": {
      "type": "object",
      "properties": {
        "iban": {
          "$ref": "#/definitions/iban"
        },
        "bban": {
          "$ref": "#/definitions/bban"
        },
        "pan": {
          "$ref": "#/definitions/pan"
        },
        "maskedPan": {
          "$ref": "#/definitions/maskedPan"
        },
        "msisdn": {
          "$ref": "#/definitions/msisdn"
        },
        "currency": {
          "$ref": "#/definitions/currency"
        }
      },
      "description": "Account reference",
      "example": {
        "iban": "BG94BANK12341234567890",
        "currency": "BGN"
      },
      "additionalProperties": false
    },
    "payee": {
      "type": "string",
      "maxLength": 70,
      "description": "Name payee",
      "example": "John Doe"
    },
    "msisdn": {
      "type": "string",
      "maxLength": 35,
      "description": "Mobile phone number.",
      "example": "+359 898 888888"
    },
    "maskedPan": {
      "type": "string",
      "maxLength": 35,
      "description": "Masked Primary Account Number",
      "example": "123456xxxxxx1234"
    },
    "pan": {
      "type": "string",
      "maxLength": 35,
      "description": "Primary Account Number according to ISO/IEC 7812.",
      "example": "5409050000000000"
    },
    "bban": {
      "type": "string",
      "description": "Basic Bank Account Number (BBAN) Identifier. This data element can be used in the body of the Consent Request Message for retrieving Account access Consent from this Account. Thisdata elements is used for payment Accounts which have no IBAN.",
      "pattern": "[a-zA-Z0-9]{1,30}",
      "example": "BARC12345612345678"
    },
    "iban": {
      "type": "string",
      "description": "IBAN of an account",
      "pattern": "[A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30}",
      "example": "BG94BANK12341234567890"
    },
    "currency": {
      "type": "string",
      "pattern": "[A-Z]{3}",
      "description": "ISO 4217 Alpha 3 currency code",
      "example": "BGN"
    },
    "amount": {
      "type": "string",
      "description": "The amount given with fractional digits, where fractions must be compliant to the currency definition.         Up to 14 significant figures. Negative amounts are signed by minus. The decimal separator is a dot.",
      "example": "5877.78"
    },
    "fundsAvailable": {
      "type": "boolean",
      "description": "Equals \"true\" if sufficient funds are available at the time of the request, \"false\" otherwise.",
      "example": true
    },
    "BAD_REQUEST_400": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "FORMAT_ERROR",
                  "PARAMETER_NOT_SUPPORTED",
                  "SERVICE_INVALID",
                  "RESOURCE_UNKNOWN",
                  "RESOURCE_EXPIRED",
                  "TIMESTAMP_INVALID",
                  "PERIOD_INVALID",
                  "SCA_METHOD_UNKNOWN",
                  "CONSENT_UNKNOWN",
                  "CARD_INVALID",
                  "NO_PIIS_ACTIVATION"
                ],
                "example": "FORMAT_ERROR"
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Bad Request",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "UNAUTHORIZED_401": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "CERTIFICATE_INVALID",
                  "CERTIFICATE_EXPIRED",
                  "CERTIFICATE_BLOCKED",
                  "CERTIFICATE_REVOKED",
                  "CERTIFICATE_MISSING",
                  "SIGNATURE_INVALID",
                  "SIGNATURE_MISSING",
                  "PSU_CREDENTIALS_INVALID",
                  "CORPORATE_ID_INVALID",
                  "CONSENT_INVALID",
                  "CONSENT_EXPIRED",
                  "TOKEN_UNKNOWN",
                  "TOKEN_INVALID",
                  "TOKEN_EXPIRED"
                ],
                "example": "TOKEN_EXPIRED"
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Unauthorized",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "FORBIDDEN_403": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "SERVICE_BLOCKED",
                  "CONSENT_UNKNOWN",
                  "RESOURCE_UNKNOWN",
                  "RESOURCE_EXPIRED"
                ],
                "example": "CONSENT_UNKNOWN"
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Forbidden",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "NOT_FOUND_404": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "RESOURCE_UNKNOWN"
                ]
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Not found",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "METHOD_NOT_ALLOWED_405": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "SERVICE_INVALID"
                ]
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Method Not Allowed",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "REQUEST_TIMEOUT_408": {
      "type": "object",
      "description": "Request Timeout"
    },
    "UNSUPPORTED_MEDIA_TYPE_415": {
      "type": "object",
      "description": "Unsupported Media Type"
    },
    "TOO_MANY_REQUESTS_429": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "ACCESS_EXCEEDED"
                ]
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Too Many Requests",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "INTERNAL_SERVER_ERROR_500": {
      "type": "object",
      "properties": {
        "tppMessages": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": {
                "$ref": "#/definitions/tppMessageCategory"
              },
              "code": {
                "type": "string",
                "enum": [
                  "INTERNAL_ERROR"
                ]
              },
              "path": {
                "type": "string"
              },
              "text": {
                "$ref": "#/definitions/tppMessageText"
              }
            },
            "additionalProperties": false,
            "required": [
              "category",
              "code"
            ]
          }
        }
      },
      "description": "Internal Server Error",
      "additionalProperties": false,
      "required": [
        "tppMessages"
      ]
    },
    "SERVICE_UNAVAILABLE_503": {
      "type": "object",
      "description": "Service Unavailable"
    },
    "tppMessageText": {
      "description": "Additional explaining text to the TPP.",
      "type": "string",
      "maxLength": 512,
      "example": "additional text information of the ASPSP up to 512 characters"
    },
    "tppMessageCategory": {
      "description": "Category of the TPP message category",
      "type": "string",
      "enum": [
        "ERROR",
        "WARNING"
      ],
      "example": "ERROR"
    }
  },
  "paths": {
    "/": {
      "post": {
        "operationId": "checkAvailabilityOfFunds",
        "description": "Creates a confirmation of funds request at the ASPSP. Checks whether a specific amount is available at point of time of the request on an account linked to a given tuple card issuer(TPP)/card number, or addressed by IBAN and TPP respectively",
        "summary": "Confirmation of Funds Request",
        "parameters": [
          {
            "name": "X-Request-ID",
            "in": "header",
            "required": true,
            "description": "ID of the request, unique to the call, as determined by the initiating party.",
            "type": "string"
          },
          {
            "name": "Consent-ID",
            "in": "header",
            "required": true,
            "description": "ID of the given consent for the PIS role",
            "type": "string"
          },
          {
            "name": "PSU-ID",
            "in": "header",
            "required": true,
            "description": "Client ID of the PSU in the ASPSP client interface. Might be mandated in the ASPSPвЂ™s documentation. Is not contained if an OAuth2 based authentication was performed in a pre-step or an OAuth2 based SCA was performed in a preceding AIS service in the same session. .",
            "type": "string"
          },
          {
            "name": "Digest",
            "in": "header",
            "required": false,
            "description": "Is contained if and only if the \"Signature\" element is contained in the header of the request.",
            "type": "string"
          },
          {
            "name": "Signature",
            "in": "header",
            "required": false,
            "description": "A signature of the request by the TPP on application level. This might be mandated by ASPSP.",
            "type": "string"
          },
          {
            "name": "TPP-Signature-Certificate",
            "in": "header",
            "required": false,
            "description": "The certificate used for signing the request, in base64 encoding. Must be contained if a signature is contained.",
            "type": "string"
          },
          {
            "name": "body",
            "in": "body",
            "required": true,
            "description": "Request body for a confirmation of funds request.",
            "schema": {
              "$ref": "#/definitions/confirmationOfFundsRequest"
            }
          },
          {
            "name": "Date",
            "in": "header",
            "required": true,
            "description": "Mandatory header element Date",
            "type": "string",
            "default": "Sun, 06 Aug 2017 15:05:37 GMT"
          }
        ],
        "responses": {
          "200": {
            "description": "The POST for a Funds request will also return 200 since it does not create a new resource.",
            "schema": {
              "$ref": "#/definitions/confirmationOfFundsResponseSuccess"
            }
          },
          "400": {
            "description": "Validation error occurred. This code will cover malformed syntax in request or incorrect data in payload.",
            "schema": {
              "$ref": "#/definitions/BAD_REQUEST_400"
            }
          },
          "401": {
            "description": "The TPP or the PSU is not correctly authorized to perform the request. Retry the request with correct authentication information.",
            "schema": {
              "$ref": "#/definitions/UNAUTHORIZED_401"
            }
          },
          "403": {
            "description": "Returned if the resource that was referenced in the path exists but cannot be accessed by the TPP or the PSU. This code should only be used for non-sensitive id references as it will reveal that the resource exists even though it cannot be accessed.",
            "schema": {
              "$ref": "#/definitions/FORBIDDEN_403"
            }
          },
          "404": {
            "description": "Returned if the resource that was referenced in the path does not exist or cannot be referenced by the TPP or the PSU. When in doubt if a specific id in the path is sensitive or not, use http code 404 instead of 403.",
            "schema": {
              "$ref": "#/definitions/NOT_FOUND_404"
            }
          },
          "405": {
            "description": "This code is only sent when the http method (PUT, POST, DELETE, GET etc) is not supported on a specific endpoint. It has nothing to do with the consent, payment or account information data model.",
            "schema": {
              "$ref": "#/definitions/METHOD_NOT_ALLOWED_405"
            }
          },
          "408": {
            "description": "The sever is still working correctly, but an individual request has timed out.",
            "schema": {
              "$ref": "#/definitions/REQUEST_TIMEOUT_408"
            }
          },
          "415": {
            "description": "The TPP has supplied a media type which the ASPSP does not support.",
            "schema": {
              "$ref": "#/definitions/UNSUPPORTED_MEDIA_TYPE_415"
            }
          },
          "429": {
            "description": "The TPP has exceeded the number of requests allowed by the consent or by the RTS.",
            "schema": {
              "$ref": "#/definitions/TOO_MANY_REQUESTS_429"
            }
          },
          "500": {
            "description": "Internal server error occurred.",
            "schema": {
              "$ref": "#/definitions/INTERNAL_SERVER_ERROR_500"
            }
          },
          "503": {
            "description": "The ASPSP server is currently unavailable. Generally, this is a temporary state.",
            "schema": {
              "$ref": "#/definitions/SERVICE_UNAVAILABLE_503"
            }
          }
        },
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ]
      }
    }
  }
}