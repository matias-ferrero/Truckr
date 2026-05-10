import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import PhotoUploader, { UploaderFile } from "./PhotoUploader";

function makeFile(name: string, type = "image/png"): File {
    return new File([new Uint8Array([1, 2, 3, 4])], name, { type });
}

describe("PhotoUploader", () => {
    it("renders the helper copy with remaining capacity", () => {
        render(<PhotoUploader files={[]} onChange={() => {}} />);
        expect(screen.getByText(/hasta 5/i)).toBeInTheDocument();
    });

    it("emits onChange when files are dropped", async () => {
        const onChange = vi.fn();
        render(<PhotoUploader files={[]} onChange={onChange} />);
        const input = screen.getByLabelText(/subir fotos/i, { selector: "input" });
        const user = userEvent.setup();
        await user.upload(input, [makeFile("a.png"), makeFile("b.png")]);
        expect(onChange).toHaveBeenCalledTimes(1);
        const [next] = onChange.mock.calls[0]!;
        expect(next).toHaveLength(2);
    });

    it("disables further uploads when the limit is reached", () => {
        const max = 5;
        const files: UploaderFile[] = Array.from({ length: max }, (_, i) => ({
            file: makeFile(`f${i}.png`),
            preview: `blob:f${i}`,
        }));
        render(<PhotoUploader files={files} onChange={() => {}} max={max} />);
        expect(screen.getByText(/llegaste al límite/i)).toBeInTheDocument();
    });

    it("removes a file when its remove button is clicked", async () => {
        const files: UploaderFile[] = [{ file: makeFile("a.png"), preview: "blob:a" }];
        const onChange = vi.fn();
        render(<PhotoUploader files={files} onChange={onChange} />);
        const user = userEvent.setup();
        await user.click(screen.getByRole("button", { name: /quitar a\.png/i }));
        expect(onChange).toHaveBeenCalledWith([]);
    });
});
