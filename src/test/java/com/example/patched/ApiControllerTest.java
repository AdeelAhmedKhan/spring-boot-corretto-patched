package com.example.patched;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class ApiControllerTest {

    private final ApiController controller = new ApiController();

    @Test
    void contextLoads() {
    }

    @Test
    void helloReturnsMessage() {
        assertThat(controller.hello()).containsKey("message");
    }

    @Test
    void runtimeReportsJvm() {
        assertThat(controller.runtime())
                .containsKeys("java.version", "java.vendor", "os.arch");
    }
}
