# Robocorp Assistant - ChatGPT Html Selector Guesser

This robot uses RPA.Assistant and RPA.OpenAI libraries to create XPath selectors for `Input` and/or `Button` web elements.

**NOTE: This is experimental, and a demonstration of potential capabnilities of Generative AI models. There are plenty of situations where this example will not work. We have published this as a portal example to promote discussion and learning, not to suggest that this is production ready code.**

This Assistant Robot:

- Authenticates to OpenAI API using your own API key (which you need to configure in the code or in Robocorp Vault)
- Opens a Robocorp Assistant UI, and asks url where to search for the elements.
- Gets all the matching elements.
- Uses ChatGPT to create `XPath` locators and give them good names.
- Tests if the selectors can find elements from the website.
- If incorrect selectors are found robot can continue the conversation with ChatGPT and ask for a fix for the non working selectors.
- Creates a json file to the `output` folder and displays the content to the user.

![XPath_Guesser](https://user-images.githubusercontent.com/84192057/227776612-f4af71a2-0073-4d25-b5d9-919874bb3e12.png)

## Learning materials

- [Robocorp Developer Training Courses](https://robocorp.com/docs/courses)
- [Documentation links on Robot Framework](https://robocorp.com/docs/languages-and-frameworks/robot-framework)
