# CPPBESSOT (C++ BackEnd Single Source of Truth):

A framework that uses OpenAI to maintain a single source of truth for the data model of a software project. It generates C++ headers, JSON serdes, ODB-based ORM headers, DB migrations, Typescript types and Zod schemas. I.e: a type-safe backend-to-frontend data model manager.

Basically, it enables one to write a web application whose backend is written in C++. This C++ web application can communicate seamlessly with a Typescript frontend without losing type-safety. We leverage Zod to enforce type safety. So you get type-safety from end to end. From C++ through to the Typescript frontend.

It works by specifying the data model in OpenAPI. Then the OpenAPI model is transpiled into both C++ headers (with JSON serdes and ODB ORM for your database of choice) and Typescript types with Zod schema descriptions.
