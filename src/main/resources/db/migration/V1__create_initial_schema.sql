CREATE TABLE app_user (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    name text NOT NULL
);

CREATE TABLE expense_group (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    invite_code text UNIQUE NOT NULL
);

CREATE TABLE member (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    user_id bigint REFERENCES app_user(id) ON DELETE SET NULL,
    group_id bigint NOT NULL REFERENCES expense_group(id) ON DELETE CASCADE,
    UNIQUE (group_id, name),
    UNIQUE (group_id, user_id) 
);

CREATE TABLE expense (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    group_id bigint NOT NULL REFERENCES expense_group(id) ON DELETE CASCADE,
    payer_id bigint NOT NULL REFERENCES member(id),
    amount numeric(7,2) NOT NULL CHECK (amount > 0),
    expense_day date NOT NULL,
    description text NOT NULL
);

CREATE TABLE share (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    member_id bigint NOT NULL REFERENCES member(id),
    expense_id bigint NOT NULL REFERENCES expense(id) ON DELETE CASCADE,
    amount numeric(7,2) NOT NULL CHECK (amount > 0),
    UNIQUE (member_id, expense_id)
);