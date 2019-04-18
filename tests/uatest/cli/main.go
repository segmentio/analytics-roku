package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/segmentio/conf"
)

type Config struct {
	WriteKey     string `conf:"writeKey"   		help:"The Segment Write Key of the project to send data to"`
	Type         string `conf:"type"       		help:"The type of the message to send"`
	UserID       string `conf:"userId"     		help:"Unique identifier for the user"`
	GroupID      string `conf:"groupId"    		help:"Unique identifier for the group"`
	Traits       string `conf:"traits"     		help:"Metadata associated with the user"`
	Event        string `conf:"event"      		help:"Name of the track event"`
	Properties   string `conf:"properties" 		help:"Metadata associated with an event, page or screen call"`
	Name         string `conf:"name"       		help:"Name of the page/screen"`
	AnonymousId  string `conf:"anonymousId" 	help:"Anonymous ID for the user"`
	Context      string `conf:"context"			help:"Context"`
	Integrations string `conf:"integrations" 	help:"Integrations"`
	PreviousID   string `conf:"previousId"		help:"Previous User ID"`
	RokuIP       string `conf:"rokuIp"	 		help:"IP address of the Roku device under test"`
}

func sendPostRequest(serverURL string, queryParams map[string]string) (int, error) {
	req, _ := http.NewRequest("POST", serverURL, nil)
	query := req.URL.Query()
	for k, v := range queryParams {
		query.Add(k, v)
	}
	req.URL.RawQuery = query.Encode()

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		fmt.Println("Error when sending request to the server:")
		fmt.Println(err)
		return 0, err
	}
	return resp.StatusCode, err
}

func main() {
	var config Config
	conf.Load(&config)

	if len(config.RokuIP) == 0 {
		// get IP address of Roku device from the environment variable if not given
		config.RokuIP = os.Getenv("ROKU_DEV_TARGET")
	}

	ecp_url := fmt.Sprintf("http://%s:8060/input", config.RokuIP)

	params := map[string]string{
		"type":         config.Type,
		"userId":       config.UserID,
		"writeKey":     config.WriteKey,
		"anonymousId":  config.AnonymousId,
		"context":      config.Context,
		"integrations": config.Integrations,
	}

	switch config.Type {
	case "track":
		params["event"] = config.Event
		params["properties"] = config.Properties
		sendPostRequest(ecp_url, params)
	case "identify":
		params["traits"] = config.Traits
		sendPostRequest(ecp_url, params)
	case "group":
		params["groupId"] = config.GroupID
		params["traits"] = config.Traits
		sendPostRequest(ecp_url, params)
	case "screen":
		params["name"] = config.Name
		params["properties"] = config.Properties
		sendPostRequest(ecp_url, params)
	case "page":
		params["name"] = config.Name
		params["properties"] = config.Properties
		sendPostRequest(ecp_url, params)
	case "alias":
		params["previousId"] = config.PreviousID
		sendPostRequest(ecp_url, params)
	default:
		fmt.Println("ERROR: unsupported Type: ", config.Type)
		os.Exit(1)
	}

}
