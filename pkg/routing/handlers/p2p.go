package handlers

import (
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/buger/jsonparser"

	"github.com/gladiusio/gladius-controld/pkg/p2p/message"
	"github.com/gladiusio/gladius-controld/pkg/p2p/peer"
	"github.com/gladiusio/gladius-controld/pkg/p2p/signature"
)

// Helper to get fields from the json body and verify the signature
func verifyBody(w http.ResponseWriter, r *http.Request) bool {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		ErrorHandler(w, r, "Error decoding body", err, http.StatusBadRequest)
		return false
	}

	messageBytes, _, _, err := jsonparser.Get(body, "message")
	if err != nil {
		ErrorHandler(w, r, "Could not find `message` in body", err, http.StatusBadRequest)
		return false
	}

	hash, err := jsonparser.GetString(body, "hash")
	if err != nil {
		ErrorHandler(w, r, "Could not find `hash` in body", err, http.StatusBadRequest)
		return false
	}

	signatureString, err := jsonparser.GetString(body, "signature")
	if err != nil {
		ErrorHandler(w, r, "Could not find `signature` in body", err, http.StatusBadRequest)
		return false
	}

	address, err := jsonparser.GetString(body, "address")
	if err != nil {
		ErrorHandler(w, r, "Could not find `address` in body", err, http.StatusBadRequest)
		return false
	}

	parsed, err := signature.ParseSignedMessage(string(messageBytes), hash, signatureString, address)
	if err != nil {
		ErrorHandler(w, r, "Couldn't parse body", err, http.StatusBadRequest)
		return false
	}
	verified, err := signature.VerifySignedMessage(parsed)
	if err != nil {
		ErrorHandler(w, r, "Error veryfing signature", err, http.StatusBadRequest)
		return false
	}

	return verified
}

// VerifySignedMessageHandler verifies the incoming message with takes the form
// of:
// {"message": "b64string", "hash": "b64string", "signature": "b64string", "address": ""}
func VerifySignedMessageHandler(w http.ResponseWriter, r *http.Request) {
	ResponseHandler(w, r, "null", strconv.FormatBool(verifyBody(w, r)))
}

/*******************************************************************************
All methods below use the account generated by the gladius account manager
*******************************************************************************/

// CreateSignedMessageHandler takes the incoming message and returns a signed
// version that includes the timestamp.
func CreateSignedMessageHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		ErrorHandler(w, r, "Error decoding body", err, http.StatusBadRequest)
		return
	}
	messageBytes, _, _, err := jsonparser.Get(body, "message")
	if err != nil {
		ErrorHandler(w, r, "Could not find `message` in body", err, http.StatusBadRequest)
		return
	}

	passphrase, err := jsonparser.GetString(body, "passphrase")
	if err != nil {
		ErrorHandler(w, r, "Could not find `passphrase` in body", err, http.StatusBadRequest)
		return
	}

	signed, err := signature.CreateSignedMessage(message.New(messageBytes), string(passphrase))
	if err != nil {
		ErrorHandler(w, r, "Could not create sign message. Passphrase likely incorrect.", err, http.StatusBadRequest)
		return
	}

	ResponseHandler(w, r, "null", signed)
}

// PushStateMessageHandler updates state with signed update and pushes state to
// a set of random peers. They then propigate it to their peers until the
// network has a consistent state
func PushStateMessageHandler(*peer.Peer) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		verified := verifyBody(w, r)

		if verified {
			// TODO: Push message to rest of network and update local state
		} else {
			ErrorHandler(w, r, "Cannot verifiy signature", nil, http.StatusBadRequest)
		}
	}
}

// GetFullStateHandler gets the current state the node has access to.
func GetFullStateHandler(*peer.Peer) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		// TODO: Return full state
	}
}

// GetContentHandler will compare the content list provided with the
// current state and return a list of links to download content from a peer that
// has the same set
func GetContentHandler(w http.ResponseWriter, r *http.Request) {

}