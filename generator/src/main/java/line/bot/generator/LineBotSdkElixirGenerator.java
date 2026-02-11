package line.bot.generator;

import java.io.File;
import java.util.List;

import static org.openapitools.codegen.utils.StringUtils.underscore;

import org.openapitools.codegen.CodegenOperation;
import org.openapitools.codegen.CodegenParameter;
import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.languages.ElixirClientCodegen;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.OperationsMap;

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

        // Force all generated modules under the LINEBotSDK namespace.
        setModuleName("LINEBotSDK");
        additionalProperties.put("moduleName", "LINEBotSDK");

        // preprocessOpenAPI adds connection.ex, request_builder.ex, deserializer.ex
        // to supportingFiles. Clear them again since we don't need them.
        supportingFiles.clear();
    }

    @Override
    public OperationsMap postProcessOperationsWithModels(OperationsMap objs, List<ModelMap> allModels) {
        OperationsMap result = super.postProcessOperationsWithModels(objs, allModels);
        for (CodegenOperation op : result.getOperations().getOperation()) {
            // Replace {paramName} with :param_name for Req's path_params option.
            String reqPath = op.path;
            for (CodegenParameter pp : op.pathParams) {
                reqPath = reqPath.replace("{" + pp.baseName + "}", ":" + underscore(pp.baseName));
            }
            op.vendorExtensions.put("x-req-path", reqPath);
        }
        return result;
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
