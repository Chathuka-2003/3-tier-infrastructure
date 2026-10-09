package com.example.threetier;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
public class NoteController {

    private final NoteRepository repository;

    public NoteController(NoteRepository repository) {
        this.repository = repository;
    }

    /** Landing page so "/" does not 404. */
    @GetMapping("/")
    public Map<String, String> root() {
        return Map.of(
                "app", "three-tier-demo",
                "try", "GET /api/hello, GET /api/notes, POST /api/notes, GET /actuator/health");
    }

    /** Tier 2 only. The "instance" value changes when the ALB routes to a different task. */
    @GetMapping("/api/hello")
    public Map<String, String> hello() {
        String instance = System.getenv().getOrDefault("HOSTNAME", "unknown");
        return Map.of("message", "Hello from the application tier", "instance", instance);
    }

    /** Tier 2 -> Tier 3: reads from MySQL. */
    @GetMapping("/api/notes")
    public List<Note> list() {
        return repository.findTop20ByOrderByIdDesc();
    }

    /** Tier 2 -> Tier 3: writes to MySQL. */
    @PostMapping("/api/notes")
    @ResponseStatus(HttpStatus.CREATED)
    public Note create(@RequestBody NoteRequest request) {
        if (request == null || request.content() == null || request.content().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "content is required");
        }
        String content = request.content().strip();
        if (content.length() > 500) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "content is too long (max 500)");
        }
        return repository.save(new Note(content));
    }

    public record NoteRequest(String content) {
    }
}
