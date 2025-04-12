//
//  BanknoteDetectionPrompt.swift
//  notescan
//
//  Created by user on 31/3/2025.
//

final class BanknoteDetectionPrompt {
    static let system: String = """
Analyze this banknote image in detail:

1. Identify the country, denomination, and issue date/series
    - Pay close attention to the item date as it could be small
2. Locate and transcribe the serial number (if visible)
3. Document all visible design elements including:
   - Portraits/figures and who they represent
   - Buildings/landmarks and their significance
   - Symbolic imagery and its meaning
   - Security features (watermarks, holograms, color-shifting ink, etc.)
   - Language(s) used on the note
4. Note the condition of the banknote (crisp/uncirculated, good, fair, poor)
5. Identify any special markings, signatures, or unique identifiers
6. Observe the color scheme and predominant colors
7. Identify both the obverse (front) and reverse (back) sides if both are shown

Focus on extracting every visible detail that would help identify and categorize this specific banknote in a collection database.
"""
    
    static let user: String = """
You are a professional currency grader and analyst. Analyze the banknote image provided and extract the following information based strictly on what is clearly visible in the image. Focus on authentic numismatic terminology and maintain high standards of accuracy, neutrality, and precision.

Do not infer or guess. If something is unclear or obscured, mark it as "Not visible"

Analyze the uploaded banknote image and extract **visible** information only. Format the output in structured JSON.

### Required Fields:

- `country`: Country of origin  
- `title`: Denomination + currency name  
- `year`: Year or range if visible, or use your banknotes knowledge
- `serialNumber`: Exact value or `"Not visible"`  
- `designElements`: List of main design elements  

### `specifications`: List of objects with `{ "title": "...", "value": "..." }` for:

- Crispness  
- Folds and creases  
- Corner condition  
- Edge integrity  
- Color vibrancy  
- Centering (e.g. “Centered (90%)”)  
- Paper quality  
- Stains or spots  
- Markings  
- Embossing clarity  
- Serial number features (e.g. ladder, radar)  
- Printing impression quality  
- Surface condition  
- Security feature visibility

### Rules:
- Use `"Not visible"` if unclear  
- Use precise, objective language  
- Do not guess or assume  
- Focus only on what’s clearly seen  

---

### ✅ Example Output (Shortened):

```json
{
  "country": "Morocco",
  "title": "50 Dirhams",
  "year": "2022",
  "serialNumber": "N98765432",
  "designElements": [
    "Portrait of King Mohammed VI",
    "Atlas Mountains background",
    "Holographic stripe"
  ],
  "specifications": [
    { "title": "Crispness", "value": "Moderately crisp" },
    { "title": "Folds", "value": "1 vertical fold" },
    { "title": "Corners", "value": "Rounded top right" },
    { "title": "Edges", "value": "Clean" },
    { "title": "Color", "value": "Vibrant and unfaded" },
    { "title": "Centering", "value": "Centered (92%)" },
    ...
  ]
}
```
"""
    
    static func rarity (banknote: String) -> String {
        return """
Search Numista and Banknote World for information on the rarity score of the {{banknote}} paper banknote
""".replaceVariables(with: ["banknote": banknote])
    }

    static func valuation (banknote: String) -> String {
        return """
Search the web for the current market value of a {{banknote}} banknote in both circulated and uncirculated conditions. Provide pricing with the currency as much as possible from reputable sources such as collector websites, auction listings, and numismatic marketplaces. If no specific values are available, return 'Value not found – please check collector forums or auction sites for recent listings.'
""".replaceVariables(with: ["banknote": banknote])
    }
    
    static func grading (specs: String) -> String {
        return """
You are a professional banknote grading expert specializing in PMG (Paper Money Guaranty) standards.

Based on the specifications provided below, return a List that includes the PMG grade, grading scale, justification, and notable strengths and flaws.

Use only the given specifications—do not guess or hallucinate missing data. Be concise, accurate, and align your reasoning with PMG grading criteria (focusing on folds, paper quality, color, embossing, centering, security features, and surface condition).

Input Format:  
The input will be a structured list of specification attributes like crispness, folds, edge condition, and so on.

Output Format (List):

Grade: Exact PMG grade, e.g., "VF 25" or "Gem Unc 65"
Grading Label: "Very Fine 25", "Gem Uncirculated 65", "About Uncirculated", etc.
Grading Scale: "PMG"
Justification: A brief explanation of the key factors that influenced this grade
Notable Strengths: A string list of the strongest positive attributes (e.g., "Sharp corners", "Full color vibrancy")
Notable Flaws: A string list of the most significant flaws (e.g., "Two vertical folds", "Minor edge nick")

Now, analyze the following specification details and provide the best possible PMG-grade evaluation:

{{specs}}
""".replaceVariables(with: ["specs": specs])
    }
}
