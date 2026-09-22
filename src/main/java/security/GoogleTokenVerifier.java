package security;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.stream.Stream;

@Component
@Slf4j
public class GoogleTokenVerifier {

    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenVerifier(@Value("${app.google.client-id}") String clientId,
            @Value("${app.google.web-client-id:}") String webClientId) {
        log.info("Google OAuth configured for client ID: {}", clientId);
        this.verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(Stream.of(clientId, webClientId).map(String::trim)
                        .filter(id -> !id.isEmpty()).distinct().toList())
                .build();
    }

    public GoogleIdToken.Payload verify(String idTokenString) {
        try {
            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken == null) {
                throw new IllegalArgumentException("Google id_token không hợp lệ");
            }
            return idToken.getPayload();
        } catch (Exception e) {
            log.error("Verify Google token failed", e);
            throw new IllegalArgumentException("Không verify được Google token: " + e.getMessage(), e);
        }
    }
}
