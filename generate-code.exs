defmodule GenerateCode do
  def main do
    {_, 0} =
      System.cmd("mvn", ["package", "-DskipTests=true"],
        cd: "generator",
        into: IO.stream(),
        stderr_to_stdout: true
      )

    File.rm_rf!("lib/gen")

    generate_clients()
    generate_webhook()

    {_, 0} =
      System.cmd("mix", ["format"],
        into: IO.stream(),
        stderr_to_stdout: true
      )
  end

  defp generate_clients do
    components = [
      "shop.yml",
      "channel-access-token.yml",
      "insight.yml",
      "liff.yml",
      "manage-audience.yml",
      "module-attach.yml",
      "module.yml",
      "messaging-api.yml"
    ]

    for source_yaml <- components do
      package_name = source_yaml |> String.replace(".yml", "") |> String.replace("-", "_")
      output_path = "lib/gen/#{package_name}"

      generate_code([
        "--model-package", "model",
        "--api-package", "api",
        "--package-name", package_name,
        "-o", output_path,
        "-i", "line-openapi/#{source_yaml}"
      ])
    end
  end

  defp generate_webhook do
    generate_code([
      "--global-property", "apiTest=false,modelDocs=false,apiDocs=false",
      "--model-package", "model",
      "--api-package", "api",
      "--package-name", "webhook",
      "-o", "lib/gen/webhook",
      "-i", "line-openapi/webhook.yml"
    ])
  end

  defp generate_code(flags) do
    cmd = "java"

    args = [
      "-cp", "./generator/target/line-bot-sdk-elixir-generator-openapi-generator-1.0.0.jar",
      "org.openapitools.codegen.OpenAPIGenerator",
      "generate",
      "-g", "line-bot-sdk-elixir-generator"
    ] ++ flags

    IO.puts("#{cmd} #{Enum.join(args, " ")}")

    case System.cmd(cmd, args, into: IO.stream(), stderr_to_stdout: true) do
      {_, 0} ->
        :ok

      {_, exit_code} ->
        IO.puts("\nCommand '#{cmd}' returned non-zero exit status #{exit_code}.")
        System.halt(1)
    end
  end
end

GenerateCode.main()
