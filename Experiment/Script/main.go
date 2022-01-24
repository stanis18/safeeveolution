package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

func run() {
	searchDir := ""
	records := make([][]string, 0)
	title := []string{"Output", "File Name", "Execution Time", "Path", "File Folder", "File Repository"}
	records = append(records, title)

	e := filepath.Walk(searchDir, func(path string, f os.FileInfo, err error) error {
		if !f.IsDir() && (strings.Contains(f.Name(), "Token.sol") || f.Name() == "ERC1155.sol") {

			slicePath := strings.Split(path, "\\")
			slicePath = slicePath[:len(slicePath)-1]

			start := time.Now()
			c, err := exec.Command("cmd.exe", "/C", "docker run --rm -v "+strings.Join(slicePath, "/")+":/contracts solc-verify:0.7 /contracts/"+f.Name()).Output()
			duration := time.Since(start)

			if err != nil {
				fmt.Println("Error: ", err)
			}

			data := []string{string(c), f.Name(), duration.String(), path, slicePath[len(slicePath)-1], slicePath[len(slicePath)-2]}
			fmt.Println(data)
			records = append(records, data)
		}
		return err
	})

	if e != nil {
		panic(e)
	}

	f, err := os.Create("results.csv")
	defer f.Close()

	if err != nil {
		log.Fatalln("failed to create the file", err)
	}

	w := csv.NewWriter(f)
	defer w.Flush()

	for _, record := range records {
		if err := w.Write(record); err != nil {
			log.Fatalln("error writing record to file", err)
		}
	}
}

func main() {
	run()
}
