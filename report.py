import sys
import json
import os


def main():
    if len(sys.argv) < 4:
        print(
            "Usage: python linting_report.py <language> <input_json> <output_report_path>"
        )
        sys.exit(1)
    language = sys.argv[1]
    in_file = sys.argv[2]
    output_report_path = sys.argv[3]

    LintingReport(language, in_file, output_report_path)


class LintingReport:
    def __init__(self, language, in_file, output_report_path):
        self.in_file = in_file
        self.output_report_path = output_report_path
        if language == "python":
            self._generate_python_report()
        if language == "terraform":
            self._generate_terraform_report()

    def _generate_terraform_report(self):
        """
        Generate a Terraform plan summary markdown file from a plan output file.

        Args:
            tf_workspace (str): The Terraform workspace name
            tfplan_file (str): Path to the Terraform plan output file
            output_file (str): Path to the output markdown summary file

        Returns:
            bool: True if successful, False if the plan file doesn't exist
        """
        import os

        # Check if the plan file exists
        if not os.path.exists(self.in_file):
            print(f"Error: Terraform plan file {self.in_file} does not exist.")
            return False

        with open(self.in_file, "r") as f:
            tfplan_content = f.read()

        resources_added = tfplan_content.count("will be created")
        resources_changed = tfplan_content.count("will be updated in-place")
        resources_destroyed = tfplan_content.count("will be destroyed")

        markdown_content = [
            "## Terraform Plan Summary",
            "",
            "**Plan Status:** `terraform plan` ",
            "",
            "**Changes detected:**",
            f"* 🟢 **Added:** {resources_added} resources",
            f"* 🟠 **Changed:** {resources_changed} resources",
            f"* 🔴 **Destroyed:** {resources_destroyed} resources",
        ]

        with open(self.output_report_path, "w") as f:
            f.write("\n".join(markdown_content))

        print(f"Terraform plan summary written to {self.output_report_path}")
        return True

    def _generate_python_report(self):
        try:
            with open(self.in_file, "r") as f:
                results = json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            results = []

        error_count = 0
        warning_count = 0
        convention_count = 0
        refactor_count = 0

        type_order = {"error": 0, "warning": 1, "convention": 2, "refactor": 3}

        for issue in results:
            if issue.get("type") == "error":
                error_count += 1
            elif issue.get("type") == "warning":
                warning_count += 1
            elif issue.get("type") == "convention":
                convention_count += 1
            elif issue.get("type") == "refactor":
                refactor_count += 1

        with open(self.output_report_path, "w") as f:
            f.write("## Python Linting Results\n\n")
            f.write(f"Scanned Python files in `backend/` directory\n\n")
            f.write("### Summary\n\n")

            if error_count + warning_count + convention_count + refactor_count == 0:
                f.write("✅ **Perfect!** No linting issues found.\n\n")
            else:
                f.write("| Type | Count | Symbol |\n")
                f.write("|------|-------|--------|\n")
                if error_count > 0:
                    f.write(f"| 🔴 Errors | {error_count} | E |\n")
                if warning_count > 0:
                    f.write(f"| 🟠 Warnings | {warning_count} | W |\n")
                if convention_count > 0:
                    f.write(f"| 🟡 Conventions | {convention_count} | C |\n")
                if refactor_count > 0:
                    f.write(f"| 🔵 Refactoring | {refactor_count} | R |\n")
                f.write("\n")

            if results:
                sorted_issues = sorted(
                    results, key=lambda issue: type_order.get(issue["type"], 999)
                )
                f.write("### Top Issues\n\n")
                for issue in sorted_issues[:10]:  # Show top 10 issues
                    path = issue.get("path", "").replace(os.getcwd() + "/", "")
                    line = issue.get("line", 0)
                    msg_id = issue.get("message-id", "")
                    msg = issue.get("message", "")
                    symbol = issue.get("symbol", "")

                    icon = (
                        "🔴"
                        if issue.get("type") == "error"
                        else (
                            "🟠"
                            if issue.get("type") == "warning"
                            else "🟡" if issue.get("type") == "convention" else "🔵"
                        )
                    )
                    f.write(f"{icon} **{path}:{line}** - {msg_id}-{msg} ({symbol})  \n")

                if len(results) > 10:
                    f.write(f"\n... and {len(results) - 10} more issues\n")

        print(error_count)


if __name__ == "__main__":
    main()
