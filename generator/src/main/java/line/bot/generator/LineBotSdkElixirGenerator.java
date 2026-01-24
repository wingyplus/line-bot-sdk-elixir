package line.bot.generator;

import org.openapitools.codegen.CodegenConfig;
import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.languages.ElixirClientCodegen;

import java.util.Arrays;
import java.util.List;

public class LineBotSdkElixirGenerator extends ElixirClientCodegen implements CodegenConfig {
    List<String> deps = Arrays.asList(
            "{:req, \"~> 0.5\"}",
            "{:ex_doc, \"~> 0.40\", only: :dev, runtime: false, warn_if_outdated: true}"
    );

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
        additionalProperties.put("deps", deps);
    }
}
