require('dotenv').config();

const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();

app.use(cors());
app.use(express.json());

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.post('/generate-plan', async (req, res) => {
  try {
    const { idea } = req.body;

    if (!idea) {
      return res.status(400).json({
        error: 'Business idea is required',
      });
    }

    const prompt = `
Create a detailed, specific, realistic HustlePilot business blueprint for:

${idea}

Rules:
- Do not use generic numbers.
- Startup costs must match this exact industry.
- Income potential must match this exact industry.
- Give detailed but direct answers.
- Do not waste words.
- Do not repeat the same format every time.
- Make it feel premium and useful.

Include these sections:

1. Business Snapshot
2. Realistic Startup Cost Breakdown
3. First 7 Days Action Plan
4. First 30 Days Action Plan
5. How To Get First Customers
6. Best Social Media Strategy
7. Monthly Income Potential
8. Tools / Equipment Needed
9. Biggest Mistakes To Avoid
10. How To Scale
11. AI Automation Ideas
12. Final HustlePilot Verdict

Make each section specific to the business idea.
`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4.1-mini',
      messages: [
        {
          role: 'system',
          content:
            'You are HustlePilot AI. You create detailed, realistic, industry-specific business plans fast.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.85,
      max_tokens: 2400,
    });

    const result = completion.choices[0].message.content;

    res.json({
      result,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: 'Failed to generate hustle plan',
    });
  }
});

const PORT = 8787;

app.listen(PORT, () => {
  console.log(`HustlePilot AI Server running on port ${PORT}`);
});