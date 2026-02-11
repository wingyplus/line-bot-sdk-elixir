package line.bot.generator;

import java.io.File;

import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.languages.ElixirClientCodegen;

import io.swagger.v3.oas.models.OpenAPI;

public class LineBotSdkElixirGenerator extends ElixirClientCodegen {
    public LineBotSdkElixirGenerator() {
        super();
        embeddedTemplateDir = templateDir = "line-bot-sdk-elixir-generator";
    }

    @Override
    public CodegenType getTag() {
        return CodegenType.OTHER;
    }

    @Override
    public String getName() {
        return "line-bot-sdk-elixir-generator";
    }

    @Override
    public String getHelp() {
        return "Generates a line-bot-sdk-elixir-generator client library.";
    }

    @Override
    public void processOpts() {
        super.processOpts();

        // Override deps to use `Req` instead.
        additionalProperties.remove("deps");

        // Clear supporting files like mix.exs, config, README, connection.ex,
        // request_builder.ex, deserializer.ex — we manage these ourselves.
        supportingFiles.clear();
    }

    @Override
    public void preprocessOpenAPI(OpenAPI openAPI) {
        super.preprocessOpenAPI(openAPI);

        // preprocessOpenAPI adds connection.ex, request_builder.ex, deserializer.ex
        // to supportingFiles. Clear them again since we don't need them.
        supportingFiles.clear();
    }

    @Override
    public String apiFileFolder() {
        return outputFolder + File.separator + "api";
    }

    @Override
    public String modelFileFolder() {
        return outputFolder + File.separator + "model";
    }
}
