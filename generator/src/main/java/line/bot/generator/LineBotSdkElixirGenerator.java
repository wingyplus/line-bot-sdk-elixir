// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 Thanabodee Charoenpiriyakij

package line.bot.generator;

import java.io.File;
import java.util.List;

import org.openapitools.codegen.CodegenOperation;
import org.openapitools.codegen.CodegenParameter;
import org.openapitools.codegen.CodegenResponse;
import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.languages.ElixirClientCodegen;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.OperationsMap;
import static org.openapitools.codegen.utils.StringUtils.camelize;
import static org.openapitools.codegen.utils.StringUtils.underscore;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.responses.ApiResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LineBotSdkElixirGenerator extends ElixirClientCodegen {
    private final Logger LOGGER = LoggerFactory.getLogger(LineBotSdkElixirGenerator.class);

    // Store the package name for use in response generation
    private String packageNamespace;

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

        // Capture the package name and convert to PascalCase for module namespace
        if (additionalProperties.containsKey("packageName")) {
            String pkgName = (String) additionalProperties.get("packageName");
            // Convert snake_case to PascalCase (e.g., channel_access_token -> ChannelAccessToken)
            packageNamespace = camelize(pkgName);
        }

        // Clear supporting files like mix.exs, config, README, connection.ex,
        // request_builder.ex, deserializer.ex — we manage these ourselves.
        supportingFiles.clear();
    }

    @Override
    public void preprocessOpenAPI(OpenAPI openAPI) {
        super.preprocessOpenAPI(openAPI);

        // Force all generated modules under the LINE.Bot namespace.
        setModuleName("LINE.Bot");
        additionalProperties.put("moduleName", "LINE.Bot");

        // preprocessOpenAPI adds connection.ex, request_builder.ex, deserializer.ex
        // to supportingFiles. Clear them again since we don't need them.
        supportingFiles.clear();
    }

    @Override
    public OperationsMap postProcessOperationsWithModels(OperationsMap objs, List<ModelMap> allModels) {
        // Call the parent implementation first - this creates ExtendedCodegenOperation,
        // ExtendedCodegenResponse with codeMappingKey() and decodedStruct() methods
        OperationsMap result = super.postProcessOperationsWithModels(objs, allModels);

        // Now add our custom processing on top
        for (CodegenOperation op : result.getOperations().getOperation()) {
            // Replace {paramName} with :param_name for Req's path_params option.
            String reqPath = op.path;
            for (CodegenParameter pp : op.pathParams) {
                reqPath = reqPath.replace("{" + pp.baseName + "}", ":" + underscore(pp.baseName));
            }
            op.vendorExtensions.put("x-req-path", reqPath);

            // Add lowercase header name for each header param
            for (CodegenParameter hp : op.headerParams) {
                hp.vendorExtensions.put("x-header-name", hp.baseName.toLowerCase());
            }
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

    @Override
    public CodegenResponse fromResponse(String responseCode, ApiResponse resp) {
        CodegenResponse response = super.fromResponse(responseCode, resp);
        return new LineExtendedCodegenResponse(response, packageNamespace);
    }

    /**
     * Extended CodegenResponse that includes the package namespace in decodedStruct().
     * This ensures the response type mapping uses the full module path like
     * LINE.Bot.ChannelAccessToken.Model.ErrorResponse instead of just
     * LINE.Bot.Model.ErrorResponse.
     */
    class LineExtendedCodegenResponse extends CodegenResponse {
        private final String packageNamespace;
        public boolean isDefinedDefault;

        public LineExtendedCodegenResponse(CodegenResponse o, String packageNamespace) {
            super();
            this.packageNamespace = packageNamespace;

            this.headers.addAll(o.headers);
            this.code = o.code;
            this.message = o.message;
            this.examples = o.examples;
            this.dataType = o.dataType;
            this.baseType = o.baseType;
            this.containerType = o.containerType;
            this.hasHeaders = o.hasHeaders;
            this.isString = o.isString;
            this.isNumeric = o.isNumeric;
            this.isInteger = o.isInteger;
            this.isLong = o.isLong;
            this.isNumber = o.isNumber;
            this.isFloat = o.isFloat;
            this.isDouble = o.isDouble;
            this.isByteArray = o.isByteArray;
            this.isBoolean = o.isBoolean;
            this.isDate = o.isDate;
            this.isDateTime = o.isDateTime;
            this.isUuid = o.isUuid;
            this.isEmail = o.isEmail;
            this.isModel = o.isModel;
            this.isFreeFormObject = o.isFreeFormObject;
            this.isDefault = o.isDefault;
            this.simpleType = o.simpleType;
            this.primitiveType = o.primitiveType;
            this.isMap = o.isMap;
            this.isArray = o.isArray;
            this.isBinary = o.isBinary;
            this.isFile = o.isFile;
            this.schema = o.schema;
            this.jsonSchema = o.jsonSchema;
            this.vendorExtensions = o.vendorExtensions;

            this.isDefinedDefault = (this.code.equals("0") || this.code.equals("default"));
        }

        public String codeMappingKey() {
            if (this.isDefinedDefault) {
                return ":default";
            }

            if (code.matches("^\\d{3}$")) {
                return code;
            }

            LOGGER.warn("Unknown HTTP status code: {}", this.code);
            return "\"" + code + "\"";
        }

        public String decodedStruct() {
            // Decode the entire response into a generic blob
            if (isMap) {
                return "%{}";
            }

            // Primitive return type, don't even try to decode
            if (baseType == null || (containerType == null && primitiveType)) {
                return "false";
            } else if (isArray && languageSpecificPrimitives().contains(baseType)) {
                return "[]";
            }

            StringBuilder sb = new StringBuilder();
            sb.append("LINE.Bot.");
            if (packageNamespace != null && !packageNamespace.isEmpty()) {
                sb.append(packageNamespace);
                sb.append(".");
            }
            sb.append("Model.");
            sb.append(baseType);

            return sb.toString();
        }
    }
}
