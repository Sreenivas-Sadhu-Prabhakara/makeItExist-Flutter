package main

import (
	"fmt"
	"log"
	"mime"
	"net/http"
)

func main() {
	// Register WASM MIME type
	mime.AddExtensionType(".wasm", "application/wasm")
	mime.AddExtensionType(".js", "text/javascript")

	dir := "./frontend/build/web"
	port := ":3000"

	fs := http.FileServer(http.Dir(dir))
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// CORS headers so API calls work from this origin
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(200)
			return
		}
		// Required for SharedArrayBuffer (needed by some Flutter renderers)
		w.Header().Set("Cross-Origin-Embedder-Policy", "credentialless")
		w.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
		fs.ServeHTTP(w, r)
	})

	http.Handle("/", handler)
	fmt.Printf("🌐 Serving Flutter web app at http://localhost%s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}
