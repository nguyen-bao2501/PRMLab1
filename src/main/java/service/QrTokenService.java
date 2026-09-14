package service;


import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;


@Service
@Slf4j
public class QrTokenService {


    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    @Value("${app.attendance.qr-duration-seconds:6000}")
    private long ttlSeconds;
    private record Entry(Long sessionId, long expiresAtMillis) {}

    public String generateForSession(Long sessionId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        long expiresAt = Instant.now().toEpochMilli() + ttlSeconds * 1000L;
        store.put(token, new Entry(sessionId, expiresAt));
        log.debug("Generated QR token for session {} (ttl={}s)", sessionId, ttlSeconds);
        return token;
    }

    public Long resolveSessionId(String token) {
        if (token == null) return null;
        Entry e = store.get(token);
        if (e == null) return null;
        if (e.expiresAtMillis() < Instant.now().toEpochMilli()) {
            store.remove(token);
            return null;
        }
        return e.sessionId();
    }

    @Scheduled(fixedDelay = 60_000)
    public void cleanupExpired() {
        long now = Instant.now().toEpochMilli();
        int before = store.size();
        store.entrySet().removeIf(e -> e.getValue().expiresAtMillis() < now);
        int removed = before - store.size();
        if (removed > 0) {
            log.debug("Cleaned up {} expired QR tokens (remaining={})", removed, store.size());
        }
    }

    public long getTtlSeconds() { return ttlSeconds; }
}